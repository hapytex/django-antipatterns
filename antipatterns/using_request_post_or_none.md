% Using `request.POST or None`

Often one initializes a form with:

<pre><code>def someview(request):
    form = MyForm(request.POST or None)
    # &hellip;</code></pre>

This is often used to construct a form for both the GET and the POST request
since it seems to make things shorter.

# Why it is a problem?

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

<pre><code>def someview(request):
    if request.method == 'POST':
        form = MyForm(request.POST)
        # &hellip;
    else:
        form = MyForm()
        # &hellip;</code></pre>
