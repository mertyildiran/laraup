# LaraUp

Upgrades an old Laravel 4.2 project to Laravel 5.8

### Usage

```Shell
./laraup.sh PATH_TO_OLD_LARAVEL_4.2_PROJECT PATH_TO_NEW_LARAVEL_5.8_PROJECT
```

### Example

```Shell
./laraup.sh ../todo-app ../upgrade/todo-app5
```

### Notes

LaraUp fixes pretty much any breaking changes except:
 - Moving from Filters to Middlewares is not fully automated so you need to do some manual fixes in Controllers and Routes
 - Anything in `start/global.php` is untouched so you might need to move them into `register()` method of `AppServiceProvider`
 - Anywhere that checks `detectEnvironment()` or `App::environment()` needs a rework
