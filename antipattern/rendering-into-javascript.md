% Rendering into JavaScript
---
author: "Abdul Aziz Barkat"
severity: 4
type: antipattern
typefa: "fas fa-ban"
tags: [javascript, json]
layers: [templates, views]
related_packages: []
---

Often one wants to pass some data to JavaScript and to do that one renders into JavaScript using Django. for example:

```html
<body>
Body Content
<script>
    let a = {{ var_1 }};
    let b = "{{ var_2|safe }}";
</script>
<script>
    let c = {{ var_3|safe }};
</script>
</body>
```

# Why is it a problem?

This is very unsafe and it makes one vulnerable to XSS attacks. Let us consider that the values of the variables rendered above are provided from the user. For demonstration purposes below is some view code with these variables set to such values that each of them will cause an alert:

```python
import json


def test_xss(request):
    context = {
        'var_1': 'alert(1)',
        'var_2': '";\nalert(2);\n"',
        'var_3': json.dumps('</script><script>alert(3);</script><script>')
    }
    return render(request, 'test.html', context)
```

This snippet might not cause much damage, **but** it can be much more dangerous. It can also be seen that even using `json.dumps` is not very safe here.

# What can be done to resolve the problem?

Don't render from Django into JavaScript, instead use the [`json_script` template filter [Django-doc]](https://docs.djangoproject.com/en/3.2/ref/templates/builtins/#json-script) and parse it's results using `JSON.parse`:

```html
<body>
Body Content
{{ var_1|json_script:"var-1-json" }}
{{ var_2|json_script:"var-2-json" }}
{{ var_3|json_script:"var-3-json" }}
<script>
    let a = JSON.parse(document.getElementById('var-1-json').textContent);;
    let b = JSON.parse(document.getElementById('var-2-json').textContent);;
</script>
<script>
    let c = JSON.parse(document.getElementById('var-3-json').textContent);;
</script>
</body>
```
