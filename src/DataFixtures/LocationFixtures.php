<?php

declare(strict_types=1);

/*
 * This file is part of the TangoMan package.
 *
 * (c) "Matthias Morin" <mat@tangoman.io>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace App\DataFixtures;

use App\Entity\Location;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Faker\Factory;

class LocationFixtures extends Fixture implements \Doctrine\Common\DataFixtures\OrderedFixtureInterface
{
    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create();

        // Create 25 origins and 25 locations
        for ($i = 1; $i <= 50; ++$i) {
            $location = new Location();
            $location->setId($faker->unique()->randomNumber());
            $location->setName($faker->userName());
            $location->setType($faker->word());
            $location->setDimension($faker->word());
            $location->setUrl($faker->url());
            $location->setCreated($faker->dateTimeThisYear());

            $manager->persist($location);
            if ($i > 25) {
                $this->addReference('location_'.$i - 25, $location);
            } else {
                $this->addReference('origin_'.$i, $location);
            }
        }

        $manager->flush();
    }

    public function getOrder(): int
    {
        return 1;
    }
}
