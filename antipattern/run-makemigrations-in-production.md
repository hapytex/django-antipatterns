% Run `makemigrations` in production
---
severity: 5
type: antipattern
typefa: "fas fa-ban"
tags: [migrations, database, deployment]
layers: models
related_packages: []
solinks: [https://stackoverflow.com/q/79057745/67579, https://stackoverflow.com/q/78978045/67579]
---

In order to deploy a Django app, it is often useful to do some administrative tasks *before* running the Django application in production, for example *migrating* the database. By adding this in the deployment workflow, it is less likely that the database will be out of sync with the software, and thus prevents problems.

Occasionally people think it is a good idea to also run `makemigrations` in the deploy flow. One would think that minimizes the odds that you forget to make migrations in the development stage, and thus a change to the models, also immediately generates migration files and can then immediately migrate the database.

# Why is it a problem?

Migrating the database is a *non-trivial problem*. There are multiple ways how you can migrate a database to get the model in sync with the database. Indeed, imagine that you have a model:

```python
from django.db import models


class MyModel(models.Model):
    my_field = models.IntegerField()
```

and we now change the model to:

```python
from django.db import models


class MyModel(models.Model):
    my_other_field = models.IntegerField()
```

now there are two reasonable ways how to migrate: assume that the field got *renamed* and thus retain the data; or assume the `my_field` was removed, and `my_other_field` is a new field. In the latter case, the question is what we do with the existing records? What value will we use for `my_other_field` for records already present in the database.

Django's `makemigrations` command therefore often prompts the user to ask what migration to perform, or needs input on what values to use for *existing* database records. This thus means that `makemigrations` can block the deploy flow, by asking for what to do, and since the deployment (typically) does not provide any input, Django will keep waiting for a response.

Let us assume that somehow Django does not need any prompts to migrate the database, it can still be quite dangerous: it could for example remove a column from a table, or even the entire table. This means that now the data is *gone*. If we would have done that in development mode, we could have seen that Django generated a migration that would destroy data, and if we migrated the *development* database, the data would be gone at that place, but this thus prevents making this mistake at the production side.

But even if the migration would somehow be trivial, it is not a good idea. It means the deployment pipeline will make migrations, and migrate the database. This means that in the `django_migrations` table, it will add an entry to mark that the migration file just generated has been applied. If you thus would copy the production database to the development database, and you run the Django application in development mode, Django will assume that migration `app_label.1234_some_message` has been applied. Perhaps at the development side, there is also such migration, but not per se the *same* one. This thus means that the database, based on the migrations, is different at the development side, than on the production side, and this makes debugging a problem harder: it could mean all sorts of queries brake, because the database is not the same, and Django does not see any issue when you would run `makemigrations`, because it sees the migrations generated in development mode, and it sees that these migrations have been marked as done by the database.


# What can be done to resolve the problem?

Run `makemigrations` when you *develop* the application. Test the migrations in development mode (preferably with the *same* type of database), and add the migration files to the git repository, and use these files when *deploying* the database. While these are a bit cryptic, you can inspect the migration files as well. These explain *what* the migration will do exactly, to prevent any surprises.

You can add `migrate` to the deploy pipeline. If the migration file was inspected and tested carefully, normally that should not be much of a problem, although adding a backup step before migrating could probably make the deployment process a bit safer.
