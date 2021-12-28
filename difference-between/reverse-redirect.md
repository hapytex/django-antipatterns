% `reverse` and `redirect`
---
type: difference-between
typefa: "fas fa-adjust"
tags: [redirect, reverse]
layers: [urls, views]
related_packages: []
solinks: [https://stackoverflow.com/a/70110725/67579]
---
The [**<code>reverse(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/urlresolvers/#reverse) and [**<code>redirect(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/topics/http/shortcuts/#redirect) functions are different for a number of reasons. The first one is that <code>reverse(&hellip;)</code> returns a *string* that is the *path* to visit the view with the given name (and optional URL parameters). <code>redirect(&hellip;)</code> on the other hand returns a [**`HttpResponseRedirect`** object [Django-doc]](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.HttpResponseRedirect). This object can be returned by the view as HTTP response. If the browser did not use Ajax or some other asynchronous tool, this HTTP response will normally trigger the browser to visit the page specified in the HTTP response. Since certain redirects can be permanent, <code>redirect(&hellip;)</code> also has a special parameter <code>permanent=&hellip;</code> such that <code>redirect(&hellip;)</code> will return a `HttpResponseRedirect` in case `permanent=False` which is the default, or a [**`HttpResponsePermanentRedirect`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.HttpResponsePermanentRedirect) for `permanent=True`. In case the redirect is permanent, the browser can cache the redirect, and might not bother the webserver anymore by visiting the view that returned the permanent redirect earlier.

Another difference is that the <code>reverse(&hellip;)</code> uses two parameters <code>args=&hellip;</code> and <code>kwargs=&hellip;</code> to fill in the values for the *URL parameters*. This is different for <code>redirect(&hellip;)</code> where one passes the positional and named parameters just as positional and named parameters. This thus means that we call <code>redirect('<i>some_view</i>', <i>some_parameter</i>, name=<i>other_parameter</i>)</code>, we get a `HttpResponseRedirect` object with as path, the string that we can obtain by calling  <code>reverse('<i>some_view</i>', args=(<i>some_parameter</i>,), kwargs={'name': <i>other_parameter</i>})</code>.

A <code>redirect(&hellip;)</code> does not per se works with a view name. Indeed, if you pass a URL to the <code>redirect(&hellip;)</code> function, like `redirect('/foo/bar/qux/')`, it will construct a `HttpResponseRedirect` that redirects to the given URL `/foo/bar/qux`, it will fail to find a view with that name and thus fallback on a HTTP redirect response with the given path. This is different for <code>reverse(&hellip;)</code> that only constructs URLs based on the name of the view, and its parameters. If no such parameter can be found, the <code>reverse(&hellip;)</code> function will raise a [**`NoReverseMatch`** exception [Django-doc]](https://docs.djangoproject.com/en/dev/ref/exceptions/#noreversematch).

Finally <code>redirect(&hellip;)</code> also accepts a model object that has a [**`.get_absolute_url()`** method [Django-doc]](https://docs.djangoproject.com/en/3.2/ref/models/instances/#get-absolute-url). In case one passes such model as first parameter, it will return a HTTP redirect response that redirects the browser to the URL constructed by that `.get_absolute_url()` method.

# Summary

|    | [<code>reverse(&hellip;)</code>](https://docs.djangoproject.com/en/dev/ref/urlresolvers/#reverse) | [<code>redirect(&hellip;)</code>](https://docs.djangoproject.com/en/dev/topics/http/shortcuts/#redirect)
|:-- |:--  |:--
| Return type | `str`ing | `HttpResponseRedirect` or `HttpResponsePermanentRedirect`
| URL parameters | through <code>args=&hellip;</code> and <code>kwargs=&hellip;</code> | positional and named parameters
| Input possibilities | only the name of the view | the name of the view, a model object with <code>.get_absolute_url(&hellip;)</code>, or a URL/path as input.
