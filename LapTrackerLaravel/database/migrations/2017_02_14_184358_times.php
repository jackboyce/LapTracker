<?php

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class Times extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('times', function (Blueprint $table) {
                       $table->increments('id');
                       $table->timestamps();
                       $table->Integer('tracknumber');
                       $table->decimal('time');
                       $table->Integer('user');
                       });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::drop('times');
    }
}
