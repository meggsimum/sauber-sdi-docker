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
              <sld:ColorMapEntry color="#FFFFFF" quantity="-1" opacity="0.1" label="noData"/>
              <sld:ColorMapEntry color="#2b83ba" label="44 µg/m³" quantity="44"/>
              <sld:ColorMapEntry color="#abdda4" label="49 µg/m³" quantity="49"/>
              <sld:ColorMapEntry color="#ffffbf" label="49 µg/m³" quantity="49"/>
              <sld:ColorMapEntry color="#fdae61" label="50 µg/m³" quantity="50"/>
              <sld:ColorMapEntry color="#d7191c" label="57 µg/m³" quantity="57"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
