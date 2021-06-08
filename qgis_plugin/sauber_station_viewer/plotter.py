from PyQt5 import QtCore, QtGui, QtWidgets

from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg, NavigationToolbar2QT as NavigationToolbar
from matplotlib.figure import Figure
import matplotlib.dates as mdates
import matplotlib.units as munits
import numpy as np
import locale

import datetime

class PlotterCanvas(FigureCanvasQTAgg):

    def __init__(self, parent=None, width=10, height=5, dpi=200):
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(1,1,1)
        super(PlotterCanvas, self).__init__(fig)

class Plotter(QtWidgets.QMainWindow):

    def __init__(self, *args, **kwargs):
        super(Plotter, self).__init__(*args, **kwargs)

    def plot(self,dataseries,station_name,component_name,unit):

        # Replace underscore
        component_annotation = component_name.replace('_',' ')

        # Use German calenadar names
        locale.setlocale(locale.LC_ALL, 'de_DE')

        # Set Axis tick formats for more intuitive formatting 
        formats = ['%y', 
                '%b', 
                '%d', 
                '%H:%M', 
                '%H:%M', 
                '%S.%f', ] 
        zero_formats = [''] + formats[:-1]
 
        zero_formats[3] = '%d-%b'
 
        offset_formats = ['',
                        '%Y',
                        '%b %Y',
                        '%d %b %Y',
                        '%d %b %Y',
                        '%d %b %Y %H:%M', ]

        converter = mdates.ConciseDateConverter(formats=formats, zero_formats=zero_formats, offset_formats=offset_formats)

        munits.registry[np.datetime64] = converter
        munits.registry[datetime.date] = converter
        munits.registry[datetime.datetime] = converter

        # y-axis: Data series
        ds = ([float(x[1]) for x in dataseries])

        # x-axis: Datetimes
        ts = ([x[0] for x in dataseries])

        sc = PlotterCanvas(self, width=10, height=5, dpi=200)
        sc.axes.plot(ts, ds)
        sc.axes.set_title(f'{station_name}: {component_annotation} ({unit})')
        sc.axes.grid(axis='both')

        sc.axes.set_ylabel(unit)

        toolbar = NavigationToolbar(sc, self)

        layout = QtWidgets.QVBoxLayout()
        layout.addWidget(toolbar)
        layout.addWidget(sc)

        widget = QtWidgets.QWidget()
        widget.setLayout(layout)
        self.setCentralWidget(widget)

        self.show()