<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->decimal('stamp_duty', 20, 6)->default(0);
        });

        Schema::table('recurring_invoices', function (Blueprint $table) {
            $table->decimal('stamp_duty', 20, 6)->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->dropColumn('stamp_duty');
        });

        Schema::table('recurring_invoices', function (Blueprint $table) {
            $table->dropColumn('stamp_duty');
        });
    }
};
