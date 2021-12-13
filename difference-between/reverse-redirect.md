% `reverse` and `redirect`
---
type: difference-between
typefa: "fas fa-adjust"
tags: [redirect, reverse]
layers: [urls, views]
related_packages: []
solinks: [https://stackoverflow.com/a/70110725/67579]
---
The [**<code>reverse(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/urlresolvers/#reverse) and [**<code>redirect(&hellip;</code>)** [Django-doc]](https://docs.djangoproject.com/en/dev/topics/http/shortcuts/#redirect)for a number of reasons. The first one is that <code>reverse(&hellip;)</code> returns a *string* that is a URL to visit that view. <code>redirect(&hellip;)</code> on the other hand returns a [**`HttpResponseRedirect`** object [Django-doc]](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.HttpResponseRedirect). This object can be returned by the view, and will normally trigger the browser to visit the page specified in the HTTP response. <code>redirect(&hellip;)</code> also has a special parameter <code>permanent=&hellip;</code> such that <code>redirect(&hellip;)</code> will return a `HttpResponseRedirect` in case `permanent=False` which is the default, or a [**`HttpResponsePermanentRedirect`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.HttpResponsePermanentRedirect) for `permanent=True`.

Another difference is that the <code>reverse(&hellip;)</code> works with two parameters <code>args=&hellip;</code> and <code>kwargs=&hellip;</code> to fill in the values for the URL patterns. This is different for <code>redirect(&hellip;)</code> where one passes the positional and named parameters just as positional and named parameters. This thus means that if you do a <code>reverse('<i>some_view</i>', args=(<i>some_parameter</i>,), kwargs={'name': <i>other_parameter</i>})</code>, you obtain a HTTP response that points to that URL with <code>redirect('<i>some_view</i>', <i>some_parameter</i>, name=<i>other_parameter</i>)</code>.

A <code>redirect(&hellip;)</code> does not per se works on a view name. Indeed, if you pass a URL to the <code>redirect(&hellip;)</code> function, like `redirect('/foo/bar/qux/')`, it will construct a `HttpResponseRedirect` that redirects to the URL `/foo/bar/qux`. This is different for <code>reverse(&hellip;)</code> that only constructs URLs based on the name of the view, and its parameters.

Finally <code>redirect(&hellip;)</code> also accepts a model object that has a [**`.get_absolute_url()`** method [Django-doc]](https://docs.djangoproject.com/en/3.2/ref/models/instances/#get-absolute-url) will result in a `HttpResponseRedirect` that redirects to the URL constructed by that `.get_absolute_url()` method.

# Summary

|    | <code>reverse(&hellip;)</code> | <code>redirect(&hellip;)</code>
|:-- |:--  |:--
| response type | `str`ing | `HttpResponseRedirect` or `HttpResponsePermanentRedirect`
| parameters | two parameters <code>args=&hellip;</code> and <code>kwargs=&hellip;</code> | positional and named parameters
| input possibilities | name of the view | name of the view, model object with <code>.get_absolute_url(&hellip;)</code> and URL/path as input.
