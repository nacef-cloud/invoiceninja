<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Update Tunisian Dinar (TND) currency precision from 2 to 3 decimals.
     * TND uses millimes as the subunit (1 dinar = 1000 millimes), requiring 3 decimal places.
     */
    public function up(): void
    {
        DB::table('currencies')
            ->where('code', 'TND')
            ->update(['precision' => 3]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('currencies')
            ->where('code', 'TND')
            ->update(['precision' => 2]);
    }
};
