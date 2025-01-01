% Users controlling a primary key
---
severity: 4
type: antipattern
typefa: "fas fa-ban"
tags: []
layers: models
related_packages: []
solinks: []
---

In Django models can be used to define records in the database. The data to populate these models often originates from the user. Every model has a single field as primary key, which is by default an `AutoField`, but can actually use (almost) any kind of field.

It is tempting to let the user pick values for the primary keys for some model objects. We can for example define a `username` field as primary key for the `User` model, and a lot of database design courses advise to use a *natural key* as primary key, so the following does not look strange:

```python
class MyUser(AbstractBaseUser):
    username = models.CharField(max_length=32, primary_key=True)
    # …
```

In that case we can let the user pick their own `username` by writing a `ModelForm` with the `username` as one of the fields.

# Why is it a problem?

There are a number of situations that might arise where updating the `.username` might have uninteded effects.

## Checking equivalence

In Django a primary key has some special logic attached to it. In fact it is the column that identifies the *full* object. This means that `MyUser(username='foo')` is equal to `MyUser(username='foo')`, indeed:

```pycon
>>> MyUser(username='foo') == MyUser(username='foo')
True
```

It thus uses that to identify a record so to speak.

## Clone a record

But a more complicated problem to handle is that Django will check if a record with the primary key exists for updating, and if not, create a record. This thus means that if you *change* the primary key of a record that already exists, and you *save* it to the database, Django will actually *clone* the record. Indeed:

```pycon
>>> user = MyUser.objects.get(username='foo')
>>> user.username = 'bar'
>>> user.save()
```

will *not* remove a record with the username `foo`, or probably even better, update the `username` of the record with primary key `'foo'` to `'bar'`, it will just insert a new record with `'bar'` as primary key, where all the columns are the same.

## Override an existing record

To make matters even worse, it allows one to even *edit* an existing record. Indeed, imagine that you have two `MyUser` records: one with `foo`, and one with `bar`, and the `MyUser` with username `foo` is changed to `bar`, it will *update* the record with primary key `'bar'`, and thus allows to override an existing record:

```pycon
>>> user_bar = MyUser.objects.get(username='bar')
>>> user_foo = MyUser.objects.get(username='foo')
>>> user_foo.username = 'bar'
>>> user_foo.age = 42
>>> user_foo.save()
>>> user_bar.refresh_from_db()
>>> user_bar.age
42
```

so while a `ModelForm` will indeed do a uniqness check, and thus reject that, certain views might accidentally override data if you use some ORM calls.

## Security vulnerabilities

To make matters even worse, some parts of Django use the primary key in authentication routines, which makes *perfect sense*. Indeed, if you login with a user, Django will store the primary key in the session variables (for the `BACKEND_SESSION_KEY` key). If a user somehow can trick a view in updating the username, and storing the (new) username in the session variable, it means the user can "steal" a session, and thus all of a sudden see the site like the other user would see that. Yes, that is unlikely, and requires some views with security problems in the Django site, but still it is not a good idea.

## Performance issues

Django very often queries the database based on the value of a primary key. Most `ForeignKey`s for example will point to the primary key column of the model they target, and thus therefore if you need the related object, Django will make a query fetching the object with a certain value for the primary key. `VARCHAR`s are usually *not* a good data format to filter on frequently. First of all the amount of bytes is typically a lot more than that of an integer (usually four or eight bytes), but to make matters worse, the data a user enters is typically not distributed evenly. Databases nowadays have support for UUIDs storing these with 16 bytes, but if they don't Django will store this in a 32-byte long `VARCHAR`, which is usually still better than storing it with the hyphens, since these always occur at the same place, and thus don't attribute any information. Still, allowing arbitrary data to be entered can slow down the database.

If one uses a hashing algorithm, and the hashing algorithm and the salt are somehow known, this can even be used as a [*Denial-of-Service (DOS) attack* vector](https://en.wikipedia.org/wiki/Denial-of-service_attack), since a malicious person can enter data in such way that the hashes collide, eventually slowing down the database completely and rendering the system unresponsive. This of course requires technical knowledge of the database, the hashing algorithm, and the salt, and therefore can generate a lot of data that collides such that the database index no longer can retrieve the corresponding record(s) efficiently.

# What can be done to resolve the problem?

Primary keys should not be used in Django (and perhaps not even in databases in general) to store *information*. You could see a primary key essentially as a "token" with no special value basides representing an objects. Sure a primary key might be an integer, or a UUID, or something else, but adding up two integer primary keys makes not much sense, or doing some modulo operations. These might be integers, but this is more a technical detail to get the mechanics to work properly. In Haskell's [**`persist`** package](https://hackage.haskell.org/package/persistent), a package to perform queries, the primary keys are wrapped in a dedicated type, exactly to prevent treating the keys as the values they use.

Our `MyUser` model of course needs a `username=…`, but it is better to make use of a (unique) model field for this. This avoids (most) of the problems we discussed:

```python
class MyUser(models.Model):
    username = models.CharField(max_length=32, unique=True)
    # …
```
