<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:sld="http://www.opengis.net/sld" version="1.0.0" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml">
  <UserLayer>
    <sld:LayerFeatureConstraints>
      <sld:FeatureTypeConstraint/>
    </sld:LayerFeatureConstraints>
    <sld:UserStyle>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:ChannelSelection>
              <sld:GrayChannel>
                <sld:SourceChannelName>1</sld:SourceChannelName>
              </sld:GrayChannel>
            </sld:ChannelSelection>
            <sld:ColorMap type="ramp">
              <sld:ColorMapEntry color="#FFFFFF" quantity="0" opacity="0.1" label="noData"/>
              <sld:ColorMapEntry color="#2b83ba" label="7 µg/m³" quantity="7"/>
              <sld:ColorMapEntry color="#abdda4" label="19 µg/m³" quantity="19"/>
              <sld:ColorMapEntry color="#ffffbf" label="22 µg/m³" quantity="22"/>
              <sld:ColorMapEntry color="#fdae61" label="25 µg/m³" quantity="25"/>
              <sld:ColorMapEntry color="#d7191c" label="32 µg/m³" quantity="32"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
