% Fetching the logged in user with a query
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [authentication, logged-in, database-query]
layers: [views]
solinks: []
---

If we use Django's [**`AuthenticationMiddleware`**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/middleware/#module-django.contrib.auth.middleware),
then the `HttpRequest`s that are passed to the view have an attribute `.user`
that we can use to obtain the logged in user, or the `AnonymousUser` in case
there is no logged in user for that request.

Often people make queries to obtain the user object, for example with:

<pre class="python"><code>from django.contrib.auth.models import User

def my_view(request):
    user = User.objects.get(<b>username=request.user</b>)
    # &hellip;</code></pre>

# Why is it a problem?

It is *unnecessary*. The `request.user` *is* a user model object. It thus has
all the attributes the user model has. By querying the database for the user
with the given username, we make an extra query, so now we query twice to obtain
user details instead of once.

Another problem with this is that we make the views *less flexible*. Indeed, we
here import the user model, if we later decide to use another user model, then
we need to rewrite the views. If we would use
[**<code>get_user_model(&hellip;)</code>**](https://docs.djangoproject.com/en/dev/topics/auth/customizing/#django.contrib.auth.get_user_model)
then it is still not very flexible, since we here make the assumption that the
user model will have a `username`, and that calling <code>str(&hellip;)</code>
on the user model will return that username. If we thus would migrate to a user
model that has only an email address, then we will still have to update the views.

# What can be done to resolve the problem?

Use [**`request.user`**&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.HttpRequest.user) directly.
This is an object of the actively used user model, so Django's `User` model by
default. It means we do not have to worry about the user model, or how it is
linked to the session.

<pre class="python"><code>def my_view(request):
    user = <b>request.user</b>
    # &hellip;</code></pre>

# Extra tips

It is possible that sometimes we want to update the user model with the values
stored in the database. Using an explicit query however is not very flexible for
the reasons explained above. In that case we can use the
[**<code>.refresh_from_db(&hellip;)</code>** method&nbsp;<sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/instances/#django.db.models.Model.refresh_from_db)
to refresh the data in the `request.user` object with values from the database:

<pre class="python"><code>def my_view(request):
    user = request.user
    # &hellip;
    # we want to retrieve the (updated) values from the database
    user<b>.refresh_from_db()</b>
    # &hellip;</code></pre>
