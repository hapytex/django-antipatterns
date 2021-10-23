% Checking request method with `if request.POST`
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [http-method, http-post, class-based-view]
layers: [views]
related_packages: []
solinks: []
---

Often people try to determine if the HTTP request is a POST request by checking `request.POST`. The view thus looks like:

<pre class="python"><code>def my_view(request):
    if <b>request.POST</b>:
        # &hellip;
    # &hellip;</code></pre>

# Why is it a problem?

Because POST requests do not per se carry data. By checking `if request.POST`, we are checking the *truthiness* of the
`request.POST`. This is a [**`QueryDict`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.QueryDict).
A `QueryDict` has as truthiness `False`, if the `QueryDict` is empty. But not all POST requests have "*payload*". For
example it is possible that a confirm box to confirm deleting an object makes a POST request, but without any data
as payload. In that case the `if request.POST` check will fail, but `request.method` will still be `'POST'`.

# What can be done to resolve the problem?

One should check the request method with:

<pre class="python"><code>def my_view(request):
    if <b>request.method == 'POST'</b>:
        # &hellip;
    # &hellip;</code></pre>

In a *class-based view*, the "routing" is handled by the view, and thus it will, based on the request method
trigger the <code>.get(&hellip;)</code>, <code>.post(&hellip;)</code>, etc. methods.

# Extra tips

One can also limit the methods that have access to a certain view with the
[**<code>@require_http_methods(&hellip;)</code>** decorator [Django-doc]](https://docs.djangoproject.com/en/dev/topics/http/decorators/#django.views.decorators.http.require_http_methods)
or related decorators. It is often better not only to *check* what method is used,
but also block requests with a request method that is not foreseen.
