% Refer to the User model directly
---
severity: 2
---

We often need to link data to the user model used by Django, for example to store
the author of a `Post`. People often refer to the [**`User`** model [Django-doc]](https://docs.djangoproject.com/en/dev/ref/contrib/auth/#user-model)
directly, for example with:

<pre><code>from django.db import models
from django.contrib.auth.models import User

class Post(models.Model):
    author = models.ForeignKey(
        <b>User</b>,
        on_delete=models.CASCADE
    )</code></pre>

# Why it is a problem?

One does not per se needs to use Django's `User` model. It is possible that one
now sticks to Django's default `User` model, but later one defines a [*custom
user model*](https://docs.djangoproject.com/en/3.1/topics/auth/customizing/#specifying-a-custom-user-model),
then one has to change all `ForeignKey`s, which is cumbersome, and error-prone.

One can make use of the [**`get_user_model()`** [Django-doc]](https://docs.djangoproject.com/en/dev/topics/auth/customizing/#django.contrib.auth.get_user_model)
to obtain a reference to the class of the user model, but this is still not
ideal: it requires to load the user model *before* we load the application where
we *reference* that model. This thus makes the project less flexible.

# What can be done to resolve the problem?

We can make use of the [**`AUTH_USER_MODEL`** setting [Django-doc]](https://docs.djangoproject.com/en/dev/ref/settings/#std:setting-AUTH_USER_MODEL).
This is a string setting that contains the <code><i>app_name</i>.<i>ModelName</i></code> of the
user model that is in use. Django thus will thus construct a `ForeignKey` with a
string as target. This target is then, when all apps are loaded, resolved to the
corresponding model.

We thus can thus let the `ForeignKey` reference the value of the
`AUTH_USER_MODEL` setting:

<pre><code>from django.conf import <b>settings</b>
from django.db import models

class Post(models.Model):
    author = models.ForeignKey(
        <b>settings.AUTH_USER_MODEL</b>,
        on_delete=models.CASCADE
    )</code></pre>
