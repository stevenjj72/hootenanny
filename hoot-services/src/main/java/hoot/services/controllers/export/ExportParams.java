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
 * @copyright Copyright (C) 2015, 2016, 2017, 2018 DigitalGlobe (http://www.digitalglobe.com/)
 */
package hoot.services.controllers.export;

import javax.ws.rs.BadRequestException;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class ExportParams {

    @JsonProperty("outputtype")
    private String outputType;

    @JsonProperty("outputname")
    private String outputName;

    @JsonProperty("textstatus")
    private Boolean textStatus;

    @JsonProperty("includehoottags")
    private Boolean includeHootTags;

    @JsonProperty("tagoverrides")
    private String tagOverrides;

    @JsonProperty("inputtype")
    @Deprecated
    private String inputType;

    @JsonProperty("TASK_BBOX")
    private String bounds;

    @JsonProperty("USER_ID")
    @Deprecated
    private String userId;

    @JsonProperty("inputFile")
    private String inputFile;

    @JsonProperty("inputId")
    private Long inputId;

    @JsonProperty("input")
    @Deprecated
    private String input;

    @JsonProperty("translation")
    private String translation;

    @JsonProperty("append")
    private Boolean append;

    @JsonProperty("USER_EMAIL")
    @Deprecated
    private String userEmail;

    @JsonProperty("MAX_NODE_COUNT_PER_TILE")
    private long maxNodeCountPerTile = -1;

    @JsonProperty("PIXEL_SIZE")
    private double pixelSize = -1.0;

    public String getOutputType() {
        return outputType;
    }

    public void setOutputType(String outputType) {
        this.outputType = outputType;
    }

    public String getOutputName() {
        return outputName;
    }

    public void setOutputName(String outputName) {
        this.outputName = outputName;
    }

    public Long getInputId() {
        return inputId;
    }

    public void setInputId(Long inputId) {
        this.inputId = inputId;
    }

    public String getInputFile() {
        return inputFile;
    }

    public void setInputFile(String inputFile) {
        this.inputFile = inputFile;
    }

    public String getTranslation() {
        return translation;
    }

    public void setTranslation(String translation) {
        this.translation = translation;
    }

    public Boolean getTextStatus() {
        return textStatus;
    }

    public void setTextStatus(Boolean textStatus) {
        this.textStatus = textStatus;
    }

    public Boolean getIncludeHootTags() {
        return includeHootTags;
    }

    public void setIncludeHootTags(Boolean includeHootTags) {
        this.includeHootTags = includeHootTags;
    }

    public String getTagOverrides() {
        return (this.tagOverrides == null) ? "" : tagOverrides;
    }

    public void setTagOverrides(String tagOverrides) {
        this.tagOverrides = tagOverrides;
    }

    public Boolean getAppend() {
        return append;
    }

    public void setAppend(Boolean append) {
        this.append = append;
    }

    @Deprecated
    public String getInputType() {
        return inputType;
    }

    @Deprecated
    public void setInputType(String inputType) {
        this.inputType = inputType;
    }

    public String getBounds() {
        return bounds;
    }

    public void setBounds(String bounds) {
        this.bounds = bounds;
    }

    @Deprecated
    public String getUserId() {
        return userId;
    }

    @Deprecated
    public void setUserId(String userId) {
        this.userId = userId;
    }

    @Deprecated
    public String getUserEmail() {
        return this.userEmail;
    }

    @Deprecated
    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public long getMaxNodeCountPerTile() {
        return maxNodeCountPerTile;
    }

    public void setMaxNodeCountPerTile(long maxNodeCountPerTile) {
        this.maxNodeCountPerTile = maxNodeCountPerTile;
    }

    public double getPixelSize() {
        return pixelSize;
    }

    public void setPixelSize(double pixelSize) {
        this.pixelSize = pixelSize;
    }

    @Override
    public String toString() {
        return "ExportParams{" +
                "outputType='" + outputType + '\'' +
                ", outputName='" + outputName + '\'' +
                ", textStatus=" + textStatus +
                ", bounds='" + bounds + '\'' +
                ", inputId='" + inputId + '\'' +
                ", inputFile='" + inputFile + '\'' +
                ", translation='" + translation + '\'' +
                ", append=" + append +
                ", maxNodeCountPerTile='" + maxNodeCountPerTile + '\'' +
                ", overrides='" + tagOverrides + '\'' +
                ", pixelSize='" + pixelSize + '\'' +
                '}';
    }

    public void validate() throws BadRequestException {
        if(input != null) {
            throw new BadRequestException("input parameter has been removed");
        }
        if(inputType != null) {
            throw new BadRequestException("inputType parameter has been removed");
        }
        if(userEmail != null) {
            throw new BadRequestException("userEmail parameter has been removed");
        }
        if(userId != null) {
            throw new BadRequestException("userId parameter has been removed");
        }
        if(inputId == null && inputFile == null) {
            throw new BadRequestException("inputId -or- inputFile must be specified");
        }
    }

    @Deprecated
    public String getInput() {
        return input;
    }

    @Deprecated
    public void setInput(String input) {
        this.input = input;
    }
}
