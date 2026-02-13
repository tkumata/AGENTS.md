class YAMLError(Exception):
    pass


def safe_load(text):
    if text is None:
        return None
    data = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#'):
            continue
        if ':' not in line:
            raise YAMLError(f"invalid line: {raw_line}")
        key, value = line.split(':', 1)
        key = key.strip()
        value = value.strip()
        if value.startswith(('"', "'")) and value.endswith(('"', "'")) and len(value) >= 2:
            value = value[1:-1]
        data[key] = value
    return data
