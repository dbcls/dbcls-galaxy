#Code for OReFiL Search
import re

def validate_input( trans, errors, inputs, page_state):
    """ escape shell meta character from query """
    inputs['query'] = "'" + re.sub("'", "__quote__", inputs['query']) + "'"
