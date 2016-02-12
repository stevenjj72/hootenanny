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
#include "EarthMoverDistanceExtractor.h"

// geos
#include <geos/geom/Geometry.h>
#include <geos/geom/Coordinate.h>
#include <geos/geom/Point.h>
#include <geos/geom/Envelope.h>
#include <geos/util/TopologyException.h>
#include <geos/geom/GeometryFactory.h>

//Qt
#include <QMatrix>
#include <QPainter>

// hoot
#include <hoot/core/Factory.h>
#include <hoot/core/util/GeometryUtils.h>
#include <hoot/core/elements/ElementVisitor.h>
#include <hoot/core/visitors/AngleHistogramVisitor.h>
#include <hoot/core/algorithms/WayHeading.h>
#include <hoot/core/GeometryPainter.h>
#include <hoot/core/MapProjector.h>
#include <hoot/core/elements/ElementProvider.h>

#include <tgs/StreamUtilsGdal.hh>

namespace hoot
{

HOOT_FACTORY_REGISTER(FeatureExtractor, EarthMoverDistanceExtractor)

EarthMoverDistanceExtractor::EarthMoverDistanceExtractor()
{
}

Mat EarthMoverDistanceExtractor::_createMat(const Envelope* env, shared_ptr<geos::geom::Geometry> geom) const
{
  double cellSize = 5.0;
  int cols = std::abs(env->getMaxX() - env->getMinX())/cellSize;
  int rows = std::abs(env->getMaxY() - env->getMinY())/cellSize;
  if (rows == 0)
  {
    rows = 1;
  }
  if (cols == 0)
  {
    cols = 1;
  }

  Mat mat(rows*cols, 3, CV_32FC1);
  int containCount = 0;
  for (int row = 0; row < rows; row++)
  {
    for (int col = 0; col < cols; col++)
    {
      double x = env->getMinX() + cellSize * col;// - cellSize/2.0;
      double y = env->getMaxY() - cellSize * row;// + cellSize/2.0;

      Coordinate c(x,y);
      auto_ptr<geos::geom::Point> p(GeometryFactory::getDefaultInstance()->createPoint(c));

      int index = row*cols + col;
      //point is inside of geometry
      bool intersect = false;
      try
      {
        intersect = geom->intersects(p.get());
      }
      catch (geos::util::TopologyException& e)
      {
        geom.reset(GeometryUtils::validateGeometry(geom.get()));
        intersect = geom->intersects(p.get());
      }

      if (intersect)
      {
        mat.at<float>(index, 0) = 1.0;
        mat.at<float>(index, 1) = row;
        mat.at<float>(index, 2) = col;
        containCount++;
      }
      else
      {
        mat.at<float>(index, 0) = 0.0;
        mat.at<float>(index, 1) = row;
        mat.at<float>(index, 2) = col;
      }
    }
  }

  if (containCount == 0)
  {
    shared_ptr<geos::geom::Point> p;
    try
    {
      p.reset(geom->getCentroid());
    }
    catch (geos::util::TopologyException& e)
    {
      geom.reset(GeometryUtils::validateGeometry(geom.get()));
      p.reset(geom->getCentroid());
    }

    int col = std::max(0, std::min<int>(cols - 1, (p->getX() - env->getMinX()) / cellSize));
    int row = std::max(0, std::min<int>(rows - 1, (env->getMaxY() - p->getY()) / cellSize));
    int index = row * cols + col;

    mat.at<float>(index, 0) = 1.0;
    mat.at<float>(index, 1) = row;
    mat.at<float>(index, 2) = col;
  }
  return mat;
}

double EarthMoverDistanceExtractor::extract(const OsmMap& map, const ConstElementPtr& target,
  const ConstElementPtr& candidate) const
{
  Envelope* targetEnv = target->getEnvelope(map.shared_from_this());
  Envelope* candidateEnv = candidate->getEnvelope(map.shared_from_this());

  //combine two envelopes
  targetEnv->expandToInclude(candidateEnv);

  //convert elements to geometries
  ElementConverter ec(map.shared_from_this());
  shared_ptr<geos::geom::Geometry> targetGeom = ec.convertToGeometry(target);
  shared_ptr<geos::geom::Geometry> candiateGeom = ec.convertToGeometry(candidate);

  //get larger geometry area
  double a1 = 0.0;
  double a2 = 0.0;
  double area = 0.0;
  try
  {
    a1 = targetGeom->getArea();
    a2 = candiateGeom->getArea();
  }
  catch (geos::util::TopologyException& e)
  {
    targetGeom.reset(GeometryUtils::validateGeometry(targetGeom.get()));
    candiateGeom.reset(GeometryUtils::validateGeometry(candiateGeom.get()));
    a1 = targetGeom->getArea();
    a2 = candiateGeom->getArea();
  }

  if (a1 >= a2)
  {
    area = a1;
  }
  else
  {
    area = a2;
  }

  //make signatures
  Mat sig1 = _createMat(targetEnv, targetGeom);
  Mat sig2 = _createMat(targetEnv, candiateGeom);

  //compare similarity of 3D using emd. emd 0 is best matching.
  //bigger number indicates less overlap of two geometries
  double emd = cv::EMD(sig1, sig2, CV_DIST_L2);
  emd = emd/area;
  return emd;
}

}
