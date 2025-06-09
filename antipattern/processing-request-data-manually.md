% Processing request data manually
---
severity: 4
type: antipattern
typefa: "fas fa-ban"
tags: [form, validating-data]
layers: [forms, views, template]
related_packages: []
solinks: []
---

Often people tend to process request data manually. For example, with:

```python3
from django.shortcuts import redirect

def my_view(request):
    if request.method == 'POST':
        email = request.POST['email']
        read_terms = request.POST['read_terms']
        password = request.POST['password']
        password2 = request.POST['password2']
        if read_terms and password == password2:
            User.objects.create_user(email=email, password=password)
            return redirect('name-of-some-view')
    # ...
```

Here we thus manually obtain the data from the `request.POST`, and we manually create a `User` record.

# Why is it a problem?

First of all, we introduce a lot of boilerplate code: if later the form sends additional data, views that process the request will have to be updated. This can be quite cumbersome if the number of views that handle such request is large. A model can start quite small, but grow in the amount of data that is required, and this means that each time we have to update the 

## Request data is not as easy as it looks

But a more severe problem is that it is not said that the request will indeed contain such keys: it is possible, for example if part of the form in the webpage was invalid, that it will not contain the request, or some users might make the request manually, and thus (deliberately or not) forget part of the data, so the request might not contain data for `email`, `read_terms`, `password`, and `password2`. One can use `request.POST.get('comment')` for example to retrieve `None` in case the key is missing, but even then the problem is often not solved: we probably do not want to create a comment record with `None`/`NULL` as comment. It is also possible that the comment is too longe to store in the database.

It thus will require a lot of custom validating, and HTML has some caveats. For example if a checkbox is not checked, it does *not* send `False` or an empty string, or something else for the name of that checkbox: it does not send the name at all. Certain names can occur multiple times in the POST dictionary, if multiple values bind with the same name, this means that for example for a `<select multiple>`, one needs to process the `request.POST.getlist('some-key')` if `some-key` can bind with multiple values.

## Importance of validating before storing

Then we need to validate the data, and this is often harder than it looks: typically databases put constraints on the number of characters a certain column can contain. If we don't validate this in the view, then depending on the database we use, it will likely reject to insert data, or truncate it to the maximum amount of characters. Truncating is probably the most problematic, since then the user does not even realize that the data has been submitted in an altered form. But even if we let the ORM insert data that is too long, and the database rejects it, it means that the ORM raises an error, and even if the view catches that error, often it is hard to introspect what the error is about, and how to report it to the user.

## Multiple errors

If the data contains two or more errors, one typically wants to send feedback on both errors. While that is technically possible, if you manually validate the data, one typically starts working with a long sequence of checks where the first check invalidates the data, and sends the error back to the user. Django's `Form`s do validation and cleaning first on each individual field, so errors tailored towards a specific field are all collected, and thus if the form is invalidated, one can see all the collected errors.

## Duplicated logic

If one does the validation in the view, often a new problem arises: that one has to *duplicate* the logic for the view that *creates* a record, and the one that *edits* a record. Often the two are very similar: you have a set of rules about how the data should look like, and whether one *creates* a new record, or *edits* that record, usually (almost) the same rules apply. Writing the same logic twice not only increases the amount of work, it is very likely that eventually the logic to create, or update will have small differences, therefore accepting certain values when you create a record and not when you update a record with these values, and vice versa.


## Unique constraint checks

Some checks are also hard to implement. Unique constraints for example. Imagine that you are not supposed to register a user with the same username, then we can check this with:

```python3
User.objects.filter(username=username).exists()
```

but if we *edit* the user, and we retain the same `username`, then this will result in an error, since the username indeed already exists: the object we edit has that username. We can fix this by using:

```python3
User.objects.exclude(pk=pk).filter(username=username).exists()
```

with `pk` the primary key of the record we want to edit, but it is thus harder than what one would expect at first.


## Multilingual support

Although validation rules can be complex, but often rules are quite simple. If one manually implements validation, one has to also write human-readable error messages, and if the application has to be multilingual, then the error messages need to be multilingual as well. Django however already ships with a lot of validators, where the error messages are already provided, in multiple languages.

If one thus writes their own validation logic, and does not use Django's translated strings, one has to do an awful lot of translations, and it is also possible one forgets to wrap a string in a `gettext` or `gettext_lazy`, so circumventing the translation process.

# What can be done to resolve the problem?

Django already has a solution for this: using a [**`Form`**](https://docs.djangoproject.com/en/stable/topics/forms/). An often heared argument is that once you use a Django form, you have to render that form as Django does, but this is not true. Indeed, one can work with a form like:

```python3
from django.shortcuts import redirect
from my_app.forms import RegisterForm


def my_view(request):
    if request.method == 'POST':
        form = RegisterForm(request.POST, request.FILES)
    # ...
```

We don't have to work with `form` to *render* it. If the `RegisterForm` has as fields an `email` field, a `password` and `password2` and a `read_terms` checkbox, then the `RegisterForm` can work with the request data submitted by a manually constructed HTML form, but regardless whether we render the form, or construct one manually, the form automates a lot of work we discussed above.

A `Form` itself can first read the data from the `request.POST` and `request.FILES`, then validate that data, and eventually offers the cleaned data. If it is a `ModelForm`, it has even logic to create or update a record, regardless from where the data originates. The template only has to make sure that the name of the form elements is according to the form fields of the `Form`.

We can also pass the `form` to the context, not to render it per se, but to inspects the `form.errors`, and show the errors on the fields accordingly.
