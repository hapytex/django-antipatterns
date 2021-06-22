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

<pre class="django"><code>&lt;body&gt;
Body Content
&lt;script&gt;
    let a = <b>{{ var_1 }}</b>;
    let b = &quot;<b>{{ var_2|safe }}</b>&quot;;
&lt;/script&gt;
&lt;script&gt;
    let c = <b>{{ var_3|safe }}</b>;
&lt;/script&gt;
&lt;/body&gt;</code></pre>

# Why is it a problem?

This is very unsafe and it makes one vulnerable to XSS attacks. Let us consider that the values of the variables rendered above are provided from the user. For demonstration purposes below is some view code with these variables set to such values that each of them will cause an alert:

<pre class="python"><code>from django.shortcuts import render
import json

def test_xss(request):
    context = {
        'var_1': <b>'alert(1)'</b>,
        'var_2': <b>'&quot;;\nalert(2);\n&quot;'</b>,
        'var_3': <b>json.dumps('&lt;/script&gt;&lt;script&gt;alert(3);&lt;/script&gt;&lt;script&gt;')</b>
    }
    return render(request, 'test.html', context)</code></pre>

This snippet might not cause much damage, **but** it can be much more dangerous. It can also be seen that even using `json.dumps` is not very safe here.

# What can be done to resolve the problem?

Don't render from Django into JavaScript, instead use the [**`json_script`** template filter [Django-doc]](https://docs.djangoproject.com/en/3.2/ref/templates/builtins/#json-script) and parse it's results using `JSON.parse`:

<pre class="django"><code>&lt;body&gt;
Body Content
{{ var_1<b>|json_script:&quot;var-1-json&quot;</b> }}
{{ var_2<b>|json_script:&quot;var-2-json&quot;</b> }}
{{ var_3<b>|json_script:&quot;var-3-json&quot;</b> }}
&lt;script&gt;
    let a = JSON.parse(document.getElementById(<b>'var-1-json'</b>).textContent);;
    let b = JSON.parse(document.getElementById(<b>'var-2-json'</b>).textContent);;
&lt;/script&gt;
&lt;script&gt;
    let c = JSON.parse(document.getElementById(<b>'var-3-json'</b>).textContent);;
&lt;/script&gt;
&lt;/body&gt;</code></pre>
