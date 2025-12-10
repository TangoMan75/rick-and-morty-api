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

use App\Entity\Episode;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Faker\Factory;

class EpisodeFixtures extends Fixture implements \Doctrine\Common\DataFixtures\OrderedFixtureInterface
{
    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create();

        for ($i = 1; $i <= 25; ++$i) {
            $episode = new Episode();
            $episode->setId($faker->unique()->randomNumber());
            $episode->setName($faker->word());
            $episode->setAirDate($faker->date());
            $episode->setEpisode($faker->word());
            $episode->setUrl($faker->url());
            $episode->setCreated($faker->dateTimeThisYear());

            $manager->persist($episode);
            $this->addReference('episode_'.$i, $episode);
        }

        $manager->flush();
    }

    public function getOrder(): int
    {
        return 2;
    }
}
