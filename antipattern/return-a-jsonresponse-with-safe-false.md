% Return a `JsonResponse` with `safe=False`
---
severity: 3
type: antipattern
tags: []
layers: [views]
---

Often people find out that you can not return a *list* as outer item in a
[**`JsonResponse`** [Django-doc]](https://docs.djangoproject.com/en/3.1/ref/request-response/#jsonresponse-objects)
and decide to use `safe=False` to still allow this. This thus looks like:

<pre class="python"><code>from django.http import JsonResponse

# &hellip;
return JsonResponse([1,4,2,5]<b>, safe=False</b>)</code></pre>

# Why is it a problem?

As the parameter already indicates, it is unsafe. *Phil Haack* published a [blog
post in
2008](https://haacked.com/archive/2008/11/20/anatomy-of-a-subtle-json-vulnerability.aspx/)
where he manages to exploit the contain of an array by overriding the `Array`
function in JavaScript.

Most browsers have fixed this exploit, but nevertheless, you never can be sure
that the browser of the client has been protected against this exploit.
Therefore it might be better to still return safe responses.

# What can be done to resolve the problem?

You can wrap the data in an extra dictionary. For example a dictionary where you
have a key `"data"` that then maps to the list:

<pre class="python"><code>from django.http import JsonResponse

# &hellip;
return JsonResponse(<b>{'data':</b> [1,4,2,5]<b>}</b>)</code></pre>


# Extra tips

Companies like *Google* and *Facebook* add extra protection. These companies
return a JSON response with extra measures for example *Google* returns:

```json
throw 1; <dont be evil> {"foo": "bar"}
```

and *Facebook* returns:

```
for(;;); {"foo": "bar"}
```

These will prevent "running" the JSON file, since it will either throw an
exception, or get stuck in an infinite loop. At the moment Django's
`JsonResponse` does not perform such formatting, but it is easy to implement
such response manually.
