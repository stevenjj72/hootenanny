/*
 * This file is part of Hootenanny.
 *
 * Hootenanny is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * --------------------------------------------------------------------
 *
 * The following copyright notices are generated automatically. If you
 * have a new notice to add, please use the format:
 * " * @copyright Copyright ..."
 * This will properly maintain the copyright information. DigitalGlobe
 * copyrights will be updated automatically.
 *
 * @copyright Copyright (C) 2015, 2016, 2017, 2018, 2019 DigitalGlobe (http://www.digitalglobe.com/)
 */
#ifndef NETWORKMERGERCREATOR_H
#define NETWORKMERGERCREATOR_H

// hoot
#include <hoot/core/elements/ConstOsmMapConsumer.h>
#include <hoot/core/conflate/merging/MergerCreator.h>

namespace hoot
{

class NetworkMatch;

class NetworkMergerCreator : public MergerCreator, public ConstOsmMapConsumer
{
public:

  static std::string className() { return "hoot::NetworkMergerCreator"; }

  NetworkMergerCreator();

  virtual bool createMergers(const MatchSet& matches, std::vector<Merger*>& mergers) const;

  virtual std::vector<CreatorDescription> getAllCreators() const;

  virtual bool isConflicting(const ConstOsmMapPtr& map, const Match* m1, const Match* m2) const;

  virtual void setOsmMap(const OsmMap* map) { _map = map; }

private:

  const OsmMap* _map;

  /**
   * Gets the largest match (in terms of number of elements, not necessarily physical size)
   */
  const NetworkMatch* _getLargest(const MatchSet& matches) const;

  /**
   * If one match contains the the rest, return the largest match.
   * Otherwise, return 0.
   */
  const NetworkMatch* _getLargestContainer(const MatchSet& matches) const;

  double _getOverlapPercent(const MatchSet& matches) const;

  double _getOverlapPercent(const NetworkMatch* m1, const NetworkMatch* m2) const;

  bool _containsOverlap(const MatchSet& matches) const;

  /**
   * Returns true if one or more matches are conflicting matches.
   */
  bool _isConflictingSet(const MatchSet& matches) const;
};

}

#endif // NETWORKMERGERCREATOR_H
