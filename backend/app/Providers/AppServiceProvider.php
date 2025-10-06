<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Schema;
use Tymon\JWTAuth\Providers\LaravelServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->register(LaravelServiceProvider::class);
    }

    public function boot()
    {
        Schema::defaultStringLength(191);
    }
}
