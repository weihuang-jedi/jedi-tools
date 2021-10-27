import os
import sys
import types
import getopt

from random import choice

#from PyQt5.QtCore import QSize, Qt, QIcon
#from PyQt5.QtWidgets import QApplication, QMainWindow, QPushButton, QLabel
#from PyQt5.QtWidgets import QWidget, QVBoxLayout, QLineEdit, QToolBar, QAction

from PyQt5.QtCore import QSize, Qt
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import (
    QAction,
    QApplication,
    QCheckBox,
    QLabel,
    QMainWindow,
    QPushButton,
    QStatusBar,
    QTabWidget,
    QToolBar,
    QWidget,
)

#------------------------------------------------------------------------------
class DisplayWindow(QWidget):
  """
  This "window" is a QWidget. If it has no parent, it
  will appear as a free-floating window as we want.
  """
  def __init__(self):
    super().__init__()
    layout = QVBoxLayout()
    self.label = QLabel('Display Window')
    layout.addWidget(self.label)
    self.setLayout(layout)

#------------------------------------------------------------------------------
#Subclass QMainWindow to customize your application's main window
class MainWindow(QMainWindow):
  def __init__(self):
    super().__init__()
   #self.show_display_window()

    self.setWindowTitle('My App')

    label = QLabel('Hello!')
    label.setAlignment(Qt.AlignmentFlag.AlignCenter)

    self.setCentralWidget(label)

    toolbar = QToolBar('My main toolbar')
    toolbar.setIconSize(QSize(16, 16))
    self.addToolBar(toolbar)

    button_action = QAction(QIcon('bug.png'), '&Your button', self)
    button_action.setStatusTip('This is your button')
    button_action.triggered.connect(self.onMyToolBarButtonClick)
    button_action.setCheckable(True)

    toolbar.addAction(button_action)
    toolbar.addSeparator()

    button_action2 = QAction(QIcon('bug.png'), '&Your button2', self)
    button_action2.setStatusTip('This is your button2')
    button_action2.triggered.connect(self.onMyToolBarButtonClick)
    button_action2.setCheckable(True)

    toolbar.addAction(button_action2)
    toolbar.addWidget(QLabel('Hello'))
    toolbar.addWidget(QCheckBox())

    self.setStatusBar(QStatusBar(self))

    menu = self.menuBar()
    file_menu = menu.addMenu('&File')
    file_menu.addAction(button_action)

  def onMyToolBarButtonClick(self, s):
    print('click', s)

#------------------------------------------------------------------------------
if __name__ == '__main__':
  debug = 1
  output = 0

  opts, args = getopt.getopt(sys.argv[1:], '', ['debug=', 'output='])

  for o, a in opts:
    if o in ('--debug'):
      debug = int(a)
    elif o in ('--output'):
      output = int(a)
   #else:
   #  assert False, 'unhandled option'

  print('debug = ', debug)
  print('output = ', output)

  app = QApplication(sys.argv)
  window = MainWindow()
  window.show()
  app.exec()

