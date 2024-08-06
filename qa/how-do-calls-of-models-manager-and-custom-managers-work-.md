% How do calls of models.Manager and custom managers work?
---
type: question-answer
typefa: "fas fa-question"
tags: []
layers: models
related_packages: []
solinks: []
---

# Question

The question is based on [this *deleted* StackOverflow post](https://stackoverflow.com/q/78833708/67579):

> I extended the models.Manager class and created a custom manager.
> 
>     class PublishedManager(models.Manager):
>         def get_queryset(self):
>             return super().get_queryset().filter(status=Post.Status.PUBLISHED)
> 
> It's more than understandable, BUT how do calls of managers work?
> 
>     objects = models.Manager() # The default manager.
>     published = PublishedManager() # Our custom manager.

> I don't address get_queryset method, I just call constructors. Then how does it work?

# Answer

It does not need to, the [**`.all()`**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/models/querysets/#all), [**<code>.get(&hellip;)</code>**&nbsp;<sup>\[Django-doc\]</sup>](https://docs.djangoproject.com/en/stable/ref/models/querysets/#get), etc. [all behind the curtains call `get_queryset()` and then perform that method on the result&nbsp;<sup>\[GitHub\]</sup>](https://github.com/django/django/blob/d5bebc1c26d4c0ec9eaa057aefc5b38649c0ba3b/django/db/models/manager.py#L82-L105):

>     class BaseManager:
>         # ...
>         
>         @classmethod
>         def _get_queryset_methods(cls, queryset_class):
>             def create_method(name, method):
>                 @wraps(method)
>                 def manager_method(self, *args, **kwargs):
>                     return getattr(self.get_queryset(), name)(*args, **kwargs)
>     
>                 return manager_method
>     
>             new_methods = {}
>             for name, method in inspect.getmembers(
>                 queryset_class, predicate=inspect.isfunction
>             ):
>                 # Only copy missing methods.
>                 if hasattr(cls, name):
>                     continue
>                 # Only copy public methods or methods with the attribute
>                 # queryset_only=False.
>                 queryset_only = getattr(method, "queryset_only", None)
>                 if queryset_only or (queryset_only is None and name.startswith("_")):
>                     continue
>                 # Copy the method onto the manager.
>                 new_methods[name] = create_method(name, method)
>             return new_methods

This inspects the methods of the `queryset` class it will wrap. Now if the `QuerySet` has a method `.all()`, it will create a small function `.all()` for the manager, that first calls the `get_queryset()` of the manager, and then `.all()` on the queryset. It does that for *all* functions defined in the queryset class, and thus creates for each a function for the manager.

These are then [injected as members in the `Manager` with&nbsp;<sup>\[GitHub\]</sup>](https://github.com/django/django/blob/d5bebc1c26d4c0ec9eaa057aefc5b38649c0ba3b/django/db/models/manager.py#L107-L118):

>     class BaseManager:
>         # ...
>         
>         @classmethod
>         def from_queryset(cls, queryset_class, class_name=None):
>             if class_name is None:
>                 class_name = "%sFrom%s" % (cls.__name__, queryset_class.__name__)
>             return type(
>                 class_name,
>                 (cls,),
>                 {
>                     "_queryset_class": queryset_class,
>                     **cls._get_queryset_methods(queryset_class),
>                 },
>             )

But there is something else that plays here: how does the manager knows what the model is? Django's models call [**<code>.contribute_to_class(&hellip;)</code>**]() on every attribute in the class, if it is available, for a manager, [that looks like&nbsp;<sup>\[GitHub\]</sup>](https://github.com/django/django/blob/d5bebc1c26d4c0ec9eaa057aefc5b38649c0ba3b/django/db/models/manager.py#L120-L126):

>     class BaseManager:
>         # ...
>         
>         def contribute_to_class(self, cls, name):
>             self.name = self.name or name
>             self.model = cls
>     
>             setattr(cls, name, ManagerDescriptor(self))
>     
>             cls._meta.add_manager(self)

This thus injects the model into the manager, which was not even known at the time you constructed the item. It does *not* sett the manager itself on the model class, but a *descriptor* of it.

The descriptor then will [delegate getting the attribute to the manager:

>     class ManagerDescriptor:
>         # ...
>     
>         def __get__(self, instance, cls=None):
>             if instance is not None:
>                 raise AttributeError(
>                     "Manager isn't accessible via %s instances" % cls.__name__
>                 )
>     
>             if cls._meta.abstract:
>                 raise AttributeError(
>                     "Manager isn't available; %s is abstract" % (cls._meta.object_name,)
>                 )
>     
>             if cls._meta.swapped:
>                 raise AttributeError(
>                     "Manager isn't available; '%s' has been swapped for '%s'"
>                     % (
>                         cls._meta.label,
>                         cls._meta.swapped,
>                     )
>                 )
>     
>             return cls._meta.managers_map[self.manager.name]

This will prevent that you can use `my_book.objects`, and thus only use `Book.objects`, and also prevents calling the manager on an abstract models.

