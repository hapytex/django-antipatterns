% Filter on arbitrary input like request.GET
---
severity: 5
type: antipattern
typefa: "fas fa-ban"
tags: []
layers: views
related_packages:
  - name: django-filter
    github: carltongibson/django-filter
solinks: []
---

A "lazy" way to allow filtering on options is to pass `request.GET`, `request.POST`, `request.query_params` as named parameters to the filter clause. For example with:

```python
MyModel.objects.filter(**request.GET)
```

If the URL is for example `/my-path?author_id=42`, then it will call `MyModel.objects.filter(author_id=42)`, and thus it can filter on arbitrary data. As long as the data
passed follows Django's ORM conventions, it can filter on all sorts of related models, and it is thus easily expandable.

# Why is it a problem?

Exactly that, it is very flexible. This means that someone with some knowledge of Django can abuse that system to obtain sensitive data. Indeed, you could for example filter on: `/my-path?author__secret__lte=M`, this can then be used to use binary search for example to "guess" the secret stored in a field named `secret` that the `Author` model might contain. The "hacker" can make a lot of requests and each time validate whether a certain object still appears in the result. If the secret is an alphanumerical string of hundred characters, it takes at most *log<sub>2</sub>(63<sup>100</sup>)=598* guesses to guess the secret. While this may look as a lot, this can easily be automated to guess secrets. A Slack API token is shorter and has a smaller *alphabet*, so that can be guessed in at most 183 requests.

Guessing a UUID, Slack API token, etc. this might be easier than expected. If the hacker makes some requests, one can easily find out, by looking when it returns a 404/500 error page how the modeling looks like, and eventually make a limited number of guesses to expose such secrets. It thus makes the system vulnerable to determine data you want to hide from an unauthenticated or different user.

# What can be done to resolve the problem?

You can first preprocess the data container and look if `request.GET` for example only contains keys that you consider valid. But that actually already is done: a package like [**`django-filter`**&nbsp;<sup>[GitHub]</sup>](https://github.com/carltongibson/django-filter/) is specifically designed for that: it will only filter on the fields you define in the filter, and thus ignore the ones the hacker is trying to guess without permissions. The Django REST framework already works with `django-filter`.

This package does not only allow to only filter with fields you think are safe, it can also clean input, such that `true` indeed maps to `True` and thus makes filtering more sensical, and can also define custom filtering options that perform more advanced filtering tasks. The most important part however is that it can hide the modeling from the user as well as prevent the user from guessing sensitive data.
