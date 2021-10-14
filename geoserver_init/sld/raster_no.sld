<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:sld="http://www.opengis.net/sld" version="1.0.0" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml">
  <UserLayer>
    <sld:LayerFeatureConstraints>
      <sld:FeatureTypeConstraint/>
    </sld:LayerFeatureConstraints>
    <sld:UserStyle>
      <sld:Name>NO</sld:Name>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:ChannelSelection>
              <sld:GrayChannel>
                <sld:SourceChannelName>1</sld:SourceChannelName>
              </sld:GrayChannel>
            </sld:ChannelSelection>
            <sld:ColorMap type="ramp">
              <ColorMapEntry color="#FFFFFF" quantity="0" opacity="0.1" label="noData"/>
              <ColorMapEntry color="#79bc6a" quantity="1" label="1 µg/m³"/>
              <ColorMapEntry color="#bbcf4c" quantity="10" label="10 µg/m³"/>
              <ColorMapEntry color="#eec20b" quantity="20" label="20 µg/m³"/>
              <ColorMapEntry color="#f29305" quantity="40" label="40 µg/m³"/>
              <ColorMapEntry color="#960018" quantity="200" label="200 µg/m³"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
