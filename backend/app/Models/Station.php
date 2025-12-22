<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Report;

class Station extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'location',
    ];

    // Relation : une station a plusieurs rapports
    public function reports()
    {
        return $this->hasMany(Report::class);
    }
}
