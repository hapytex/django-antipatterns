% A GET request with side-effects
---
severity: 4
type: antipattern
tags: []
layers: [views]
---
Often people construct views that have side, effects, for example:

<pre class="python"><code>def remove_comment(request, comment_pk):
    Comment.objects.<b>filter(</b>
        comment_id=comment_pk
    )<b>.delete()</b>
    # &hellip;</code></pre>

# Why is it a problem?

Because this violates the HTTP standard. In the section [*safe methods* of the HTTP specifications [w3.org]](https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.1)
it specifies that:

> In particular, the convention has been established **that the GET** and HEAD methods **SHOULD NOT have the significance** of taking an action **other than retrieval**. These methods **ought to be considered "safe"**.

A GET request should thus not create, update, or delete entities.

This is important because other actors on the internet assume that a GET request
is safe. For example if a browser will not give a warning if you refresh the
browser with an additional GET request, whereas most browsers will do that for
a POST request.

Search engines have web crawlers that look for URLs on pages, and will make GET
requests to these pages to analyze the page that is returned and look for more
URLs. This thus means that a GET request of such crawler might accidentally
create, remove and update entities.

Django also does not offer security mechanisms like a CSRF-token for GET
requests. This thus makes [cross-site request forgery (CSRF) [wiki]](https://en.wikipedia.org/wiki/Cross-site_request_forgery)
easier.

# What can be done to resolve the problem?

One should use POST, PUT, PATCH, or DELETE requests to update entities. These
are the HTTP methods designed for this. One can use for example the
[**`@require_http_methods`** decorator [Django-doc]](https://docs.djangoproject.com/en/3.1/topics/http/decorators/#django.views.decorators.http.require_http_methods)
to restrict a view to certain HTTP methods. This will return a [HTTP 405 "*Method Not Allowed*" response [wiki]](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#4xx_client_errors)
to warn the client that this request was not allowed:

<pre class="python"><code>from django.views.decorators.http import <b>require_http_methods</b>

<b>@require_http_methods(['POST'])</b>
def remove_comment(request, comment_pk):
    Comment.objects.<b>filter(</b>
        comment_id=comment_pk
    <b>).delete()</b>
    # &hellip;</code></pre>

The HTML page should thus use a mini `<form>` to produce the POST request, or an
AJAX call.
