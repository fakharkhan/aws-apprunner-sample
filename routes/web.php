<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/health', function () {
    try {
        // Basic health check - verify application is running
        $status = [
            'status' => 'healthy',
            'timestamp' => now()->toIso8601String(),
            'service' => 'aws-apprunner-sample',
        ];

        // Optional: Check database connectivity if configured
        if (config('database.default') !== 'sqlite' || file_exists(database_path('database.sqlite'))) {
            try {
                DB::connection()->getPdo();
                $status['database'] = 'connected';
            } catch (\Exception $e) {
                $status['database'] = 'disconnected';
                // Don't fail health check if DB is down, just report it
            }
        }

        return response()->json($status, 200);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'unhealthy',
            'error' => $e->getMessage(),
            'timestamp' => now()->toIso8601String(),
        ], 503);
    }
});
