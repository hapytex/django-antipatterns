% Using `request.POST or None`
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [http-request, post, form-invalid]
layers: [forms]
---

Often one initializes a form with:

<pre class="python"><code>def someview(request):
    form = MyForm(request.POST or None)
    # &hellip;</code></pre>

This is often used to construct a form for both the GET and the POST request
since it seems to make things shorter.

# Why is it a problem?

Although it is common, a POST request does not *per se* has content. The `or`
operator evaluates the *truthiness* of the `request.POST` operand, and if it is
`False`, it will take the right operand (so `None`). This means that even if it
is a POST request, it will take `None`, and thus as result the form is *not*
bounded.

If the form is not bounded, then `form.is_valid()` will return `False`, even if
an empty `QueryDict` for `request.POST` was a valid request.

# What can be done to resolve the problem?

We can branch based on the request *method*, and use `request.POST` in case of a
POST request:

<pre class="python"><code>def someview(request):
    <b>if request.method == 'POST'</b>:
        form = MyForm(request.POST, request.FILES)
        # &hellip;
    else:
        form = MyForm()
        # &hellip;</code></pre>
