# function_registry.py

FUNCTION_REGISTRY = {}

def register_func(name):
    """装饰器：注册一个函数"""
    def decorator(func):
        FUNCTION_REGISTRY[name] = func
        return func
    return decorator
