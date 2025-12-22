<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    */

    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    // SECURITY WARNING: ['*'] allows all origins (development only)
    // In production, restrict to specific origins: ['https://yourdomain.com']
    'allowed_origins' => ['*'], // ou ['http://localhost:5173'] pour limiter

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
