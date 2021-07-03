% Use <code>.get(&hellip;)</code> to retrieve the object in a view
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [http, permission-denied, http-404, not-found, authorization]
layers: [views]
---

In a view, people often retrieve the object with the
[**<code>.get(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#get)
call, for example:

<pre class="python"><code>def post_details(request, pk):
    mypost = Post.objects<b>.get(pk=pk)</b>
    # &hellip;</code></pre>

# Why is it a problem?

If no such `Post` object exists, then the call will raise a `Post.DoesNotExist`
exception. If this exception is not handled properly, it means that the server
will return a *HTTP 500* response, which means that the error should be at the
*server* side, but here the problem is at the *client* side, since there simply
exists no `Post` for the given primary key.

# What can be done to resolve the problem?

We can make use of
[**<code>get_object_or_404(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/topics/http/shortcuts/#get-object-or-404).
This function will raise a `Http404` exception in case the model object does not
exists. This will then be handled by Django and eventually a HTTP 404 response
will be returned:

<pre class="python"><code>from django.shortcuts import <b>get_object_or_404</b>

def post_details(request, pk):
    mypost = <b>get_object_or_404(</b>Post, pk=pk<b>)</b>
    # &hellip;</code></pre>
