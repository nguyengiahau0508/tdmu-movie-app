<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'user_id',
        'order_id',
        'trans_id',
        'amount',
        'status',
        'order_info',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
