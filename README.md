# LaraUp

Automatically upgrades your old Laravel 4.2 project to 5.8

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
 - We assume that you are using [vlucas/phpdotenv](https://github.com/vlucas/phpdotenv) to load the environment variables from `.env` in
your Laravel 4.2 project. So we currently don't cover `.env.X.php` files in the upgrades. If you are not using `vlucas/phpdotenv` package in your project
then start to use it on your project before running LaraUp.
 - Moving from Filters to Middlewares is not fully automated yet so you need to do some manual fixes in your Controllers and Routes
 - Anything in `start/global.php` is untouched so you might need to move them into `register()` method of `AppServiceProvider`
 - Anywhere that checks `detectEnvironment()` or `App::environment()` needs a rework
