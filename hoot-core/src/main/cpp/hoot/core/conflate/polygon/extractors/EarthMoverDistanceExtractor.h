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
 * @copyright Copyright (C) 2005 VividSolutions (http://www.vividsolutions.com/)
 * @copyright Copyright (C) 2015 DigitalGlobe (http://www.digitalglobe.com/)
 */
#ifndef EARTHMOVERDISTANCEEXTRACTOR_H
#define EARTHMOVERDISTANCEEXTRACTOR_H

//opencv
#include <opencv/cv.h>

// hoot
#include <hoot/core/conflate/extractors/FeatureExtractor.h>
#include <hoot/core/elements/Element.h>
#include <hoot/core/util/ElementConverter.h>

namespace hoot
{
using namespace cv;

/**
 * This extractor uses the Earth Movers Distance to calculate the distance
 * between two distributions
 *
 */
class EarthMoverDistanceExtractor : public FeatureExtractor
{
public:
  EarthMoverDistanceExtractor();

  static string className() { return "hoot::EarthMoverDistanceExtractor"; }

  virtual string getClassName() const { return EarthMoverDistanceExtractor::className(); }

  virtual DataFrame::FactorType getFactorType() const { return DataFrame::Numerical; }

  virtual DataFrame::NullTreatment getNullTreatment() const
  {
    return DataFrame::NullAsMissingValue;
  }

  virtual double extract(const OsmMap& map, const shared_ptr<const Element>& target,
    const shared_ptr<const Element>& candidate) const;

protected:
  Mat _createMat(const OsmMap& map, const ConstElementPtr& e) const;
};

}

#endif // EARTHMOVERDISTANCEEXTRACTOR_H
