% Rendering content after a successful POST request
---
severity: 3
type: antipattern
tags: []
layers: [views]
---

A view sometimes renders content after a *successful* POST request, for example:

<pre class="python"><code>from django.shortcuts import render

def my_view(request):
    if request.method == 'POST':
        form = MyForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return <b>render(request, '<i>some_success_template.html</i>')</b>
    else:
        form = MyForm()
    return render(request, '<i>some_template.html</i>', {'form': form})</code></pre>

# Why is it a problem?

This means that for this specific HTTP request, it returns a HTTP response. If
the client later performs a refresh on the browser, it means that the browser
will make *another* POST request. This can result in buying the same products
multiple times, posting the same comment multiple times, etc. This is something
one often wants to avoid.

# What can be done to resolve the problem?

The [*Post/Redirect/Get* architectural pattern [wiki]](https://en.wikipedia.org/wiki/Post/Redirect/Get)
sends a HTTP 302 or HTTP 303 response, which is a *non-permanent* redirect to the next page. The browser
will then make a GET request to that other view. If later the client refreshes
the browser, the browser will again make a GET request to the new URL, and thus
no longer make a second POST request.

The view thus then looks like:

<pre class="python"><code>from django.shortcuts import redirect, render

def my_view(request):
    if request.method == 'POST':
        form = MyForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return <b>redirect('<i>name-of-some-view</i>')</b>
    else:
        form = MyForm()
    return render(request, '<i>some_template.html</i>', {'form': form})</code></pre>
