# =============================================================
#  RTL-SecCheck -- Vivado Tcl integration
# -------------------------------------------------------------
#  One-time setup (paste into Vivado Tcl Console):
#      source {C:/Users/99754/Desktop/RTL-SecCheck/tcl/seccheck.tcl}
#
#  Commands:
#      seccheck start                        start the local backend (auto-run on load)
#      seccheck scan  <rtl_dir> [engines]    engines: pvd|lavd|both (default both; "none" rejected)
#      seccheck status [scan_id]
#      seccheck report [scan_id]
#      seccheck fix   <finding_id> [scan_id]
#      seccheck graph [scan_id]              graph view in browser
#      seccheck web   [scan_id | page]       web UI in browser
#      seccheck help
#
#  NOTE: all console output is plain ASCII on purpose. Vivado's
#  Tcl console on Windows uses the local code page (GBK) and
#  cannot render UTF-8 Chinese text correctly. For full reports
#  with proper encoding use: seccheck web
# =============================================================

package require http 2.5
# force DIRECT connections for every request in this package (Vivado's older
# http does not accept -proxyfilter per geturl, so set it globally here)
if {[catch {::http::config -proxyfilter sec_noproxy}]} { }

# Server address. Default is local. To connect a SHARED server (e.g. a lab-mate
# host running RTL-SecCheck), set the variable BEFORE sourcing this file:
#      set ::SEC_BASE "http://192.168.1.100:8321"
#      source {C:/path/to/seccheck.tcl}
if {![info exists ::SEC_BASE]} {
    set ::SEC_BASE "http://127.0.0.1:8321"
}
set ::SEC_LAST ""
set ::SEC_PID ""

# project root (the folder that contains start.bat) - derived from this file
set ::SEC_ROOT [file normalize [file join [file dirname [info script]] ..]]

# ---- low level GET, returns utf-8 decoded body, throws on error ----
#: force a DIRECT connection (never route localhost
# through an inherited http_proxy, which would break 127.0.0.1 requests).
proc sec_noproxy {host} { return {} }

proc sec_http {path {timeout 60000}} {
    set url "${::SEC_BASE}${path}"
    if {[catch {::http::geturl $url -timeout $timeout} token]} {
        error "RTL-SecCheck backend not reachable at $::SEC_BASE.\n       -> run: seccheck start\n       ($token)"
    }
    set st    [::http::status $token]
    set ncode [::http::ncode $token]
    set data  [::http::data $token]
    ::http::cleanup $token
    if {$st ne "ok"} {
        error "request failed (status: $st) while calling $url\n       -> is the backend running? try: seccheck start"
    }
    if {$ncode != 200} {
        set head [join [lrange [split [string trim $data] "\n"] 0 2] "\n"]
        if {[string length $head] > 300} { set head [string range $head 0 300] }
        error "backend returned HTTP $ncode:\n$head"
    }
    return [encoding convertfrom utf-8 $data]
}

# ---- resolve scan id: explicit arg, else last scan of this session ----
proc sec_resolve_id {{scan_id ""}} {
    if {$scan_id ne ""} { return $scan_id }
    if {$::SEC_LAST ne ""} { return $::SEC_LAST }
    error "no scan id given and no previous scan in this session.\n       -> run: seccheck scan <rtl_dir>  first (or pass a scan id)."
}

# ---- backend lifecycle ----
# bulletproof fallback: parse the OS port table (no sockets, no proxy,
# no Tcl event loop involved - cannot be fooled by a busy Vivado).
proc sec_port_listening {} {
    if {[catch {exec netstat -ano} out]} { return 0 }
    foreach ln [split $out "\n"] {
        if {[regexp {:8321\s+\S+\s+LISTENING} $ln]} { return 1 }
    }
    return 0
}

# generous timeout: when Vivado is busy its Tcl event loop is slow, and a
# short probe timeout aborts client-side even though the server answered.
proc sec_backend_alive {{timeout 5000}} {
    if {![catch {::http::geturl "${::SEC_BASE}/api/settings" -timeout $timeout} token]} {
        set st [::http::status $token]
        set nc [::http::ncode $token]
        ::http::cleanup $token
        if {$st eq "ok" && $nc == 200} { return 1 }
    }
    # http probe can fail while Vivado is busy - fall back to netstat
    return [sec_port_listening]
}

# proper blocking sleep: bare "after ms" does NOT wait inside a running script
# (it only schedules a timer; the timer needs the event loop). Use vwait.
proc sec_sleep {ms} {
    set ::SEC_SLEEP_TICK 0
    after $ms [list set ::SEC_SLEEP_TICK 1]
    if {[catch {vwait ::SEC_SLEEP_TICK}]} {
        # event loop unavailable - fall back to a few short http-timeout waits
        catch {::http::geturl "${::SEC_BASE}/api/settings" -timeout $ms}
    }
}

proc seccheck_start_backend {} {
    # re-check first with a generous timeout: a busy Vivado can make the
    # quick probe at source time fail even though the backend is running
    if {[sec_backend_alive]} {
        puts ">> backend already running at $::SEC_BASE - nothing to do."
        return
    }
    # launch uvicorn DIRECTLY (no start.bat / no cmd chain) - robust and windowless
    set py [file join $::SEC_ROOT backend .venv Scripts python.exe]
    if {![file exists $py]} { set py "python" }
    set bindir [file nativename [file join $::SEC_ROOT backend]]
    set logf   [file nativename [file join $::SEC_ROOT backend service.log]]
    puts ">> backend not running - launching it (background, log: backend/service.log) ..."
    if {[catch {
        exec [file nativename $py] -E -s -u -m uvicorn --app-dir $bindir main:app \
             --host 127.0.0.1 --port 8321 > $logf 2>@1 &
    } pipeid]} {
        error "could not launch uvicorn: $pipeid\n       -> check that dependencies are installed (see README Quick start)."
    }
    set ::SEC_PID ""
    catch { set ::SEC_PID [lindex [pid $pipeid] 0] }
    puts -nonewline ">> waiting for backend "
    flush stdout
    for {set i 0} {$i < 15} {incr i} {
        sec_sleep 1000
        if {[sec_backend_alive]} {
            puts "\n>> backend is UP at $::SEC_BASE (pid $::SEC_PID - stop it with: seccheck stop)"
            return
        }
        puts -nonewline "."
        flush stdout
    }
    puts ""
    error "backend did not come up within ~90 s.\n       -> check backend/service.log for errors (see README Quick start).\n       -> if backend/service.log shows the server running, just run your\n          seccheck command again - the probe can be slow while Vivado is busy."
}

proc seccheck_start {} {
    if {[sec_backend_alive]} {
        puts ">> backend already running at $::SEC_BASE - nothing to do."
        return
    }
    seccheck_start_backend
}

proc sec_find_backend_pid {} {
    # find the pid listening on 8321 from the OS port table (works even when
    # the backend was started by another session / outside this Vivado)
    if {[catch {exec netstat -ano} out]} { return "" }
    foreach ln [split $out "\n"] {
        if {[regexp {:8321\s+\S+\s+LISTENING\s+(\d+)} $ln -> p]} { return $p }
    }
    return ""
}

proc seccheck_stop {} {
    set p ""
    if {[info exists ::SEC_PID] && $::SEC_PID ne ""} {
        set p $::SEC_PID
    } else {
        set p [sec_find_backend_pid]
    }
    if {$p eq ""} {
        puts ">> backend is not running - nothing to stop."
        return
    }
    if {[catch {exec taskkill /PID $p /T /F} msg]} {
        puts ">> stop failed: $msg (backend may already be down)"
    } else {
        puts ">> backend (pid $p) stopped."
    }
    set ::SEC_PID ""
}

proc sec_open_browser {url} {
    if {[catch {exec rundll32 url.dll,FileProtocolHandler $url &} err]} {
        puts ">> could not launch browser automatically: $err"
        puts ">> open this URL manually:"
        puts "   $url"
    } else {
        puts ">> opened in browser: $url"
    }
}

# ---------------- commands ----------------
proc sec_common_parent {dirs} {
    set first [lindex $dirs 0]
    set last  [lindex $dirs end]
    set len [string length $first]
    if {[string length $last] < $len} { set len [string length $last] }
    set n 0
    while {$n < $len && [string index $first $n] eq [string index $last $n]} { incr n }
    set s [string range $first 0 [expr {$n - 1}]]
    set i [string last / $s]
    if {$i < 1} { return $first }
    return [string range $s 0 [expr {$i - 1}]]
}

proc seccheck_scanproj {{engines both}} {
    # scan ALL Verilog sources of the CURRENTLY OPEN Vivado project
    if {[catch {set files [concat [get_files -quiet *.v] [get_files -quiet *.sv]]} err]} {
        error "cannot read project sources - open a project first. ($err)"
    }
    set files [lsort -unique $files]
    if {![llength $files]} {
        error "no .v/.sv sources in the current project (add design sources first)."
    }
    set dirs {}
    foreach f $files { lappend dirs [file dirname [file normalize $f]] }
    set dirs [lsort -unique $dirs]
    if {[llength $dirs] == 1} {
        set target [lindex $dirs 0]
    } else {
        set target [sec_common_parent $dirs]
        puts ">> sources spread over [llength $dirs] dirs; scanning common parent: $target"
    }
    puts ">> found [llength $files] source file(s) in project"
    seccheck_scan $target $engines
}

proc seccheck_scan {rtl_dir {engines both}} {
    if {![file isdirectory $rtl_dir]} {
        error "RTL directory not found: $rtl_dir"
    }
    set d [file normalize $rtl_dir]
    set q [::http::formatQuery dir $d engines $engines]
    set out [sec_http "/api/tcl/scan?$q"]
    if {[regexp {SCAN_ID\s+(\S+)} $out -> id]} {
        set ::SEC_LAST $id
        puts ">> tracking scan $id (type 'seccheck status' to poll)"
    }
    puts $out
}

proc seccheck_status {{scan_id ""}} {
    set id [sec_resolve_id $scan_id]
    set q [::http::formatQuery scan_id $id]
    puts [sec_http "/api/tcl/status?$q"]
}

proc seccheck_report {{scan_id ""}} {
    set id [sec_resolve_id $scan_id]
    set q [::http::formatQuery scan_id $id]
    set out [sec_http "/api/tcl/report?$q"]
    foreach ln [split $out "\n"] {
        if {$ln eq ""} { continue }
        if {[string match "FINDING\t*" $ln]} {
            set f [split $ln "\t"]
            puts [format "%-8s %-8s %-24s %s" \
                  [lindex $f 1] "\[[lindex $f 2]\]" [lindex $f 3] [lindex $f 4]]
            set desc [lindex $f 5]
            if {$desc ne ""} {
                puts [format "%-45s%s" "" $desc]
            }
        } else {
            puts $ln
        }
    }
    puts ">> full report:  seccheck web report"
    puts ">> fix details:  seccheck fix <finding_id>"
}

proc seccheck_fix {finding_id {scan_id ""}} {
    set id [sec_resolve_id $scan_id]
    puts ">> generating fix for $finding_id (LLM call, may take 30-60 s) ..."
    set q "[::http::formatQuery scan_id $id]&[::http::formatQuery finding $finding_id]"
    puts [sec_http "/api/tcl/fix?$q" 180000]
    puts ">> patch + verification details:  seccheck web report"
}

proc seccheck_graph {{scan_id ""}} {
    set id [sec_resolve_id $scan_id]
    set q "[::http::formatQuery scan_id $id]&what=graph"
    set out [sec_http "/api/tcl/open?$q"]
    if {[regexp {URL\s+(\S+)} $out -> url]} {
        sec_open_browser $url
    } else {
        puts $out
    }
}

proc seccheck_web {{a ""} {b ""}} {
    if {$a eq ""} {
        sec_open_browser $::SEC_BASE
        return
    }
    if {[string match "S-*" $a]} {
        set id $a
        set what "report"
        if {$b ne ""} { set what $b }
        set q "[::http::formatQuery scan_id $id]&what=[::http::formatQuery what $what]"
        set out [sec_http "/api/tcl/open?$q"]
        if {[regexp {URL\s+(\S+)} $out -> url]} {
            sec_open_browser $url
        } else {
            puts $out
        }
    } else {
        # first arg is a page name (report|graph) -> use last scan
        set id [sec_resolve_id ""]
        seccheck_web $id $a
    }
}

proc seccheck_help {} {
    puts {
RTL-SecCheck commands (Vivado Tcl Console):
  seccheck start                       start the local backend (auto-run on load if not running)
  seccheck stop                        stop the backend started from this session
  seccheck scanproj [engines]          scan ALL sources of the current Vivado project
  seccheck scan  <rtl_dir> [engines]   start scan; engines: pvd|lavd|both (default both; "none" rejected)
  seccheck status [scan_id]            show scan progress / logs
  seccheck report [scan_id]            list findings (like the web report page)
  seccheck fix  <finding_id>           LLM fix suggestion (needs API key, 30-60 s)
  seccheck graph [scan_id]             open graph visualization in browser
  seccheck web  [scan_id|page]         open web UI (page: report|graph)
  seccheck help                        this help

Examples:
  seccheck scanproj                     scan the currently open project
  seccheck scan {C:/work/myrtl}         full scan (both engines)
  seccheck scan {C:/work/myrtl} pvd     permission-flow analysis only
  seccheck status
  seccheck report
  seccheck fix V-001
  seccheck graph
  seccheck web graph
}
}

# ---------------- dispatcher ----------------
proc seccheck {cmd args} {
    if {[catch {
        switch -- $cmd {
            start     { seccheck_start }
            stop      { seccheck_stop }
            scan      { seccheck_scan    {*}$args }
            scanproj  { seccheck_scanproj {*}$args }
            status    { seccheck_status  {*}$args }
            report  { seccheck_report {*}$args }
            fix     { seccheck_fix    {*}$args }
            graph   { seccheck_graph  {*}$args }
            web     { seccheck_web    {*}$args }
            help    { seccheck_help }
            default { puts "unknown command: $cmd"; seccheck_help }
        }
    } err]} {
        puts "ERROR: $err"
        puts "(type 'seccheck help' for usage)"
    }
    return
}

puts "RTL-SecCheck Tcl bridge loaded. Type:  seccheck help"

# auto-start the backend if it is not running yet
if {![sec_backend_alive]} {
    if {[catch {seccheck_start_backend} err]} {
        puts "WARNING: $err"
    }
}
