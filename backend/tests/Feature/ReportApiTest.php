<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Station;
use App\Models\Report;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

class ReportApiTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $station;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Create test user
        $this->user = User::factory()->create([
            'name' => 'test_user',
            'role' => 'pompiste'
        ]);
        
        // Create test station
        $this->station = Station::create([
            'name' => 'Test Station',
            'location' => 'Test Location'
        ]);
    }

    /** @test */
    public function it_can_create_a_report_with_sales_calculation()
    {
        Sanctum::actingAs($this->user);

        $reportData = [
            'station_id' => $this->station->id,
            'date' => now()->format('Y-m-d'),
            'super1_index' => 1000,
            'super2_index' => 2000,
            'super3_index' => 3000,
            'gazoil1_index' => 1500,
            'gazoil2_index' => 2500,
            'gazoil3_index' => 3500,
            'stock_sup_9000' => 100,
            'stock_sup_10000' => 200,
            'stock_sup_14000' => 300,
            'stock_gaz_10000' => 150,
            'stock_gaz_6000' => 250,
            'versement' => 5000.00,
            'depenses' => [100, 200, 300],
            'autres_ventes' => [50, 75],
            'commandes' => [1000, 2000],
        ];

        $response = $this->postJson('/api/reports', $reportData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'message',
                'report' => [
                    'id',
                    'station_id',
                    'user_id',
                    'date',
                    'super_sales',
                    'gazoil_sales',
                    'total_sales'
                ]
            ]);

        // First report should have sales equal to indexes (no previous report)
        $report = $response->json('report');
        $this->assertEquals(6000, $report['super_sales']); // 1000 + 2000 + 3000
        $this->assertEquals(7500, $report['gazoil_sales']); // 1500 + 2500 + 3500
        $this->assertEquals(13500, $report['total_sales']);
    }

    /** @test */
    public function it_calculates_sales_correctly_with_previous_report()
    {
        Sanctum::actingAs($this->user);

        // Create previous day report
        Report::create([
            'station_id' => $this->station->id,
            'user_id' => $this->user->id,
            'date' => now()->subDay()->format('Y-m-d'),
            'super1_index' => 500,
            'super2_index' => 1000,
            'super3_index' => 1500,
            'gazoil1_index' => 800,
            'gazoil2_index' => 1200,
            'gazoil3_index' => 1800,
            'stock_sup_9000' => 100,
            'stock_sup_10000' => 200,
            'stock_sup_14000' => 300,
            'stock_gaz_10000' => 150,
            'stock_gaz_6000' => 250,
        ]);

        // Create today's report
        $reportData = [
            'station_id' => $this->station->id,
            'date' => now()->format('Y-m-d'),
            'super1_index' => 1000,
            'super2_index' => 2000,
            'super3_index' => 3000,
            'gazoil1_index' => 1500,
            'gazoil2_index' => 2500,
            'gazoil3_index' => 3500,
            'stock_sup_9000' => 100,
            'stock_sup_10000' => 200,
            'stock_sup_14000' => 300,
            'stock_gaz_10000' => 150,
            'stock_gaz_6000' => 250,
            'versement' => 5000.00,
        ];

        $response = $this->postJson('/api/reports', $reportData);

        $report = $response->json('report');
        
        // Sales should be current - previous
        // Super: (1000 + 2000 + 3000) - (500 + 1000 + 1500) = 6000 - 3000 = 3000
        $this->assertEquals(3000, $report['super_sales']);
        
        // Gazoil: (1500 + 2500 + 3500) - (800 + 1200 + 1800) = 7500 - 3800 = 3700
        $this->assertEquals(3700, $report['gazoil_sales']);
        
        // Total: 3000 + 3700 = 6700
        $this->assertEquals(6700, $report['total_sales']);
    }

    /** @test */
    public function it_returns_paginated_reports()
    {
        Sanctum::actingAs($this->user);

        // Create 25 reports
        for ($i = 0; $i < 25; $i++) {
            Report::create([
                'station_id' => $this->station->id,
                'user_id' => $this->user->id,
                'date' => now()->subDays($i)->format('Y-m-d'),
                'super1_index' => 1000,
                'super2_index' => 2000,
                'super3_index' => 3000,
                'gazoil1_index' => 1500,
                'gazoil2_index' => 2500,
                'gazoil3_index' => 3500,
                'stock_sup_9000' => 100,
                'stock_sup_10000' => 200,
                'stock_sup_14000' => 300,
                'stock_gaz_10000' => 150,
                'stock_gaz_6000' => 250,
            ]);
        }

        $response = $this->getJson('/api/reports');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data',
                'current_page',
                'per_page',
                'total'
            ]);

        // Should return 20 items per page
        $this->assertCount(20, $response->json('data'));
        $this->assertEquals(25, $response->json('total'));
    }

    /** @test */
    public function it_calculates_stats_correctly_with_json_fields()
    {
        Sanctum::actingAs($this->user);

        // Create reports with depenses and autres_ventes
        Report::create([
            'station_id' => $this->station->id,
            'user_id' => $this->user->id,
            'date' => now()->format('Y-m-d'),
            'super1_index' => 1000,
            'super2_index' => 2000,
            'super3_index' => 3000,
            'gazoil1_index' => 1500,
            'gazoil2_index' => 2500,
            'gazoil3_index' => 3500,
            'stock_sup_9000' => 100,
            'stock_sup_10000' => 200,
            'stock_sup_14000' => 300,
            'stock_gaz_10000' => 150,
            'stock_gaz_6000' => 250,
            'versement' => 5000.00,
            'depenses' => [100, 200, 300], // Total: 600
            'autres_ventes' => [50, 75, 25], // Total: 150
        ]);

        Report::create([
            'station_id' => $this->station->id,
            'user_id' => $this->user->id,
            'date' => now()->subDay()->format('Y-m-d'),
            'super1_index' => 500,
            'super2_index' => 1000,
            'super3_index' => 1500,
            'gazoil1_index' => 800,
            'gazoil2_index' => 1200,
            'gazoil3_index' => 1800,
            'stock_sup_9000' => 100,
            'stock_sup_10000' => 200,
            'stock_sup_14000' => 300,
            'stock_gaz_10000' => 150,
            'stock_gaz_6000' => 250,
            'versement' => 3000.00,
            'depenses' => [150, 250], // Total: 400
            'autres_ventes' => [100], // Total: 100
        ]);

        $response = $this->getJson('/api/dashboard/stats');

        $response->assertStatus(200)
            ->assertJson([
                'total_reports' => 2,
                'total_versements' => 8000, // 5000 + 3000
                'total_depenses' => 1000, // 600 + 400
                'total_autres_ventes' => 250, // 150 + 100
            ]);
    }

    /** @test */
    public function it_enforces_unique_constraint_per_station_per_user_per_date()
    {
        Sanctum::actingAs($this->user);

        $reportData = [
            'station_id' => $this->station->id,
            'date' => now()->format('Y-m-d'),
            'super1_index' => 1000,
            'super2_index' => 2000,
            'super3_index' => 3000,
            'gazoil1_index' => 1500,
            'gazoil2_index' => 2500,
            'gazoil3_index' => 3500,
            'stock_sup_9000' => 100,
            'stock_sup_10000' => 200,
            'stock_sup_14000' => 300,
            'stock_gaz_10000' => 150,
            'stock_gaz_6000' => 250,
        ];

        // First creation should succeed
        $this->postJson('/api/reports', $reportData)->assertStatus(201);

        // Second creation with same station/date/user should update, not create new
        $reportData['versement'] = 1000;
        $this->postJson('/api/reports', $reportData)->assertStatus(201);

        // Should still have only 1 report for this user
        $this->assertEquals(1, Report::where('user_id', $this->user->id)->count());
        
        // And versement should be updated
        $report = Report::where('user_id', $this->user->id)->first();
        $this->assertEquals(1000, $report->versement);

        // Another user can create a report for the same station/date
        $otherUser = User::factory()->create(['role' => 'pompiste']);
        Sanctum::actingAs($otherUser);
        $this->postJson('/api/reports', $reportData)->assertStatus(201);

        // Now there should be 2 reports (one per user)
        $this->assertEquals(2, Report::count());
        $this->assertEquals(1, Report::where('user_id', $otherUser->id)->count());
    }
}
