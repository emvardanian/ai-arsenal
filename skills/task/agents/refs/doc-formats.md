# Documentation Formats

## JSDoc / TSDoc (JavaScript/TypeScript)

```typescript
/**
 * Brief description of what the function does.
 *
 * @param paramName - Description of parameter
 * @returns Description of return value
 * @throws {ErrorType} When this error occurs
 * @example
 * const result = myFunction('input');
 */
```

## Docstrings (Python)

```python
def my_function(param: str) -> dict:
    """Brief description of what the function does.

    Args:
        param: Description of parameter.

    Returns:
        Description of return value.

    Raises:
        ValueError: When this error occurs.

    Example:
        >>> result = my_function('input')
    """
```
