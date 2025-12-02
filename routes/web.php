<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/health', function () {
    // Simple health check - just verify application is running
    // Don't check database to avoid startup issues
    return response()->json([
        'status' => 'healthy',
        'timestamp' => now()->toIso8601String(),
        'service' => 'aws-apprunner-sample',
    ], 200);
});
