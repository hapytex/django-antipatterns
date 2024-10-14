% passing function references to reverse
---
severity: 4
type: antipattern
typefa: "fas fa-ban"
tags: [urls, views, reverse, redirect]
layers: urls
related_packages: []
solinks: ['https://stackoverflow.com/questions/78035103/in-django-is-it-possible-to-use-reverse-redirect-with-a-view-function-not-stri']
---

The [**<code>reverse(&hellip;)</code>** function&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/urlresolvers/#reverse) allows to pass the names of views as well as references to functions. Indeed, for example with:

```python
#app_name/urls.py

from app_name.views import some_view

urlpatterns = [
    path('some-path', some_view, name='something'),
]
```

and then determine the path with `reverse(some_view)`.

# Why is it a problem?

Django determines the reverse URL with some quite complicated and chaotic logic, where ech `URLResolver` has a `.reverse_dict`. A <code>path(&hellip;)</code> for example with an [**<code>include(&hellip;)</code>**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/urls/#include), has its own `.reverse_dict`.

The problem starts to arise when `app_name` is used. In that case, it does not "backpropagate" content to the *parent* `.reverse_dict`. This thus means that the parent dictionary will not contain entries to these view function references, and therefore can not reverse these. The problem is most severe when an (independent) Django app does that, since then we don't have control if someone later includes the paths in the Django app with an app name specified.

Since we thus have no control over that, using the reference to reverse was probably a misfeature of Django in the first place.

# What can be done to resolve the problem?

*Name* the paths, and use the (namespaced) app. Of course even that has a problem, since again we don't know when a view will eventually get namespaced. Using the view handler could have been used as a unique way to reference to a path, but at the moment it is not, so as for now, we need to work with the "collapsed structure" of *referencing by name*.

We thus don't work with <s>`reverse(some_view)`</s>, but with `reverse('something')`, with the `app_name` as prefix if that is defined.
