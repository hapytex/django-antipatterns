% Data duplication
---
severity: 4
type: antipattern
typefa: "fas fa-ban"
tags: [3nf, thirdnormalform]
layers: models
related_packages: []
solinks: []
---

Coding is often not much more than converting input into output. For example if a `Project` can have an archive date, we probably sometimes need to determine if the project is archived. In that case we check if the archive date is not `None`/`NULL`, and if that is the case, we check if the archive date is in the past.

It is tempting to store that in the database. After all, it can make our lives more comfortable. We could for example define a `Project` class with:

```python3
from django.db import models


class Project(models.Model):
    archive_date = models.DateField(null=True, blank=True, default=None)
    is_archived = models.BooleanField(default=False)
```

We can now filter on `Project.objects.filter(is_archived=True)` to get all archived projects. So the problem is solved, isn't it?

# Why is it a problem?

It is very tempting to make an additional field. But often it is *not* a good idea. Sure we can filter on the `is_archived` column, but what keeps the `is_archived` column in sync?

All views that modify `archive_date` must also update `is_archived`, and vice versa. This may look simple at first, but it means that if you `.update(archive_date=date(2019, 11, 25))`, you need to update the field. If you use `.save(update_fields=('archive_date',))`, you need to remember to include `is_archived`.

If `is_archived` does not only depend on fields of the `Project` model, but related models, then it even gets more complicated. If for example a project is not archived if there is still a `Task` that is not archived, it means that creating a task, removing a task, updating a task, etc. all can have impact on the `Project`. So eventually it is almost impossible to tell what to do. Often one also uses [*signals*](https://www.django-antipatterns.com/antipattern/signals.html) for that, a tool that has its own pitfalls.

To make matters even worse in the scenario described above, even if we don't do anything with the `Project` model, a `Project` can change from unarchived to archived: if we set the date on July 18<sup>th</sup>, 2035, and it is still 2025, we don't have to worry, but eventually some process will have to set `is_archived` to `True`. There is tooling that can schedule a task to run at a certain moment in time. But this is often not completely reliable: imagine that you use celery, but at a certain point celery fails, then it will not update the project in time. If you use for example a Redis database that lives and dies with a particular deploy, then when redeploying, celery does not even know anymore what tasks it was supposed to run. So while celery is definitely a good tool, it is often not good to rely too much on tasks scheduled years in advance.

Getting rid of functional dependencies is something already well understood in database design: [*Third Normal Form (3NF)*](https://en.wikipedia.org/wiki/Third_normal_form) aims to eliminate such functional dependencies: if we need those, and we can not say through computation how a column *Y* depends on another column *X* (or multiple columns), it is usually stored in a lookup table, to prevent having to store the functional dependency multiple times, and thus risking *data inconsistency* and *anomalies*.


# What can be done to resolve the problem?

Don't duplicate data in the database. We can work with a property, that just determines the value when we need it, like:

```python3
from django.db import models
from django.utils import timezone


class Project(models.Model):
    archive_date = models.DateField(null=True, blank=True, default=None)

    @property
    def is_archived(self):
        if self.archive_date is None:
            return False
        return self.archive_date <= timezone.now().date()
```

We can also attach a setter to it if we want to set a value `is_archived`, which than handles the case accordingly:

```python3
from django.db import models
from django.utils import timezone


class Project(models.Model):
    archive_date = models.DateField(null=True, blank=True, default=None)

    @property
    def is_archived(self):
        if self.archive_date is None:
            return False
        return self.archive_date <= timezone.now().date()

    @is_archived.setter
    def is_archived(self, value):
        if value:
            self.archive_date = timezone.now().date()
        else:
            self.archive_date = None
```
