from datetime import datetime
from string import Template
import re
import csv

alphabetic = re.compile('\D+')

# Getting together some templates
pstuff = 'align="center" style="margin: 0px;"'
tdstyle = 'style="font-style: normal; font-family: Garamond; color: navy; font-size: 36pt; font-weight: normal;"'
timetdstyle = 'style="text-align: center; color: navy;"'
slide_template = Template('<p $pstuff><strong>COURT SCHEDULE - $date</strong></p><p $pstuff><table border="1" align="center" style="border: 1px solid navy;"><tbody><tr><td $tdstyle><strong>$jobtitle</strong></td><td $timetdstyle><strong>TIME</strong></td><td $tdstyle><strong>EVENT/NOTES</strong></td><td $tdstyle><strong>LOCATION</strong></td></tr>$rows</tbody></table></p>')
row_template = Template(
    '<td $tdstyle>$judge</td><td $timetdstyle>$time</td><td $tdstyle>$event</td><td $tdstyle>$location</td></tr>')

first_template = Template('<p $pstuff><strong><i>$event</i></strong></p><p ${pstuff}>$location&nbsp;&nbsp;&nbsp;$time&nbsp;&nbsp;&nbsp;Judge $judge</p>')
intro_template = Template(
        '<p $pstuff>&nbsp;&nbsp;<strong><font color="#000080"><i>COURT SCHEDULE</i></font></strong></p><p $pstuff><strong>$dow</strong></p><p $pstuff>$date</p><p $pstuff>&nbsp;</p>$firstappear<p $pstuff>&nbsp;</p>$misdemeanor')


def parse_judge_schedule():
    """This massages our schedule data out of the csv created by save_schedule().

       It assumes we only have 2 categories of people: Judges and non-judges.
       A lot of the gymnastics are in handling the freaky formatting we end up with
       due to the original Excel file being decorated/intended for humans.

       row[0] is the judge's name
       row[4] is the time
       row[6] is the event or note
       row[8], if it exists, is the room/courtroom
       row[10] is the floor
    """
    cs = csv.reader(open(r'/home/dpflug/cschedule.csv'), dialect='excel')
    today = datetime.strptime(next(cs)[6], "%B %d, %Y")
    next(cs)  # Skip the headers
    schedules = {'judges': [],
                 'other': [],
                 '1st_appearances': [],
                 'traffic_misdemeanor': []}
    current_judge = ''
    out_of_order = False
    current_position = 'judges'
    for row in cs:
        # Let's make this a bit more plain to read
        r = dict(zip(['judge', 'blank', 'blank', 'blank',
                      'time', 'blank',
                      'event', 'blank',
                      'room', 'blank',
                      'floor'], row))
        if alphabetic.match(r['judge']):
            # When names are out of order, they're either a visiting judge or
            # some other official.
            if out_of_order or r['judge'].lower() < current_judge.lower():
                out_of_order = True
                if "y" in input("Is {} a judge?".format(r['judge'])):
                    current_position = 'judges'
                    sort_judges = True
                else:
                    current_position = "other"
            current_judge = r['judge'].title()
            if current_judge == "Williams":
                # Judge Ritterhoff-Williams wants to appear as such
                current_judge = "RitterhoffWilliams"
            elif current_judge.lower() == "mccune":
                current_judge = "McCune"
        # Don't include mediations or internal things
        if (r['floor'] and r['event'].strip() and not r['event'] ==
                'Mediations' and r['event'].find("Personnel") == -1):
            # First appearances and "traffic & misdemeanor" get treated differently
            # They show up on the intro page
            if current_position != "other":
                if ('st appear' in r['event'].lower()):
                    current_position = '1st_appearances'
                elif ('traffic' in r['event'].lower() and
                      'misdemeanor' in r['event'].lower()):
                    current_position = 'traffic_misdemeanor'
                else:
                    current_position = 'judges'

            # Now, let's add it to our schedule data
            schedules[current_position].append((current_judge,
                                                r['time'],
                                                get_event(r['event']),
                                                get_location(r)))

    # Sort list of judges
    schedules["judges"].sort(key=lambda k: k[0])
    # and others
    schedules["other"].sort(key=lambda k: k[0])

    return(today, schedules)

def generate_intro(data):
    if data['1st_appearances']:
        firsta = data['1st_appearances'][0]
        fa = first_template.substitute(dict(zip(['judge',
                                                 'time',
                                                 'event',
                                                 'location'],
                                                firsta)),
                                       pstuff=pstuff)
    else:
        fa = ''

    if data['traffic_misdemeanor']:
        trafmis = data['traffic_misdemeanor'][0]
        tm = first_template.substitute(dict(zip(['judge',
                                               'time',
                                               'event',
                                               'location'],
                                              trafmis)),
                                     pstuff=pstuff)
    else:
        tm = ''

    return(intro_template.substitute(pstuff=pstuff,
                                     date=today.strftime("%B %d, %Y"),
                                     dow=today.strftime("%A"),
                                     firstappear=fa,
                                     misdemeanor=tm))

def generate_table(data, judges):
    rows = ''
    if judges:
        jt = 'JUDGE'
    else:
        jt = 'General Magistrate/Hearing Officer'
    for row in data:
        rows += row_template.substitute(dict(zip(['judge',
                                                  'time',
                                                  'event',
                                                  'location'],
                                                 row)),
                                        tdstyle=tdstyle,
                                        timetdstyle=timetdstyle)

    return(slide_template.substitute(pstuff=pstuff,
                                     tdstyle=tdstyle,
                                     timetdstyle=timetdstyle,
                                     date=today.strftime("%m/%d/%Y").lstrip("0"),
                                     jobtitle=jt,
                                     rows=rows))

def paginate_schedule(sched, per_page):
    for start in range(0, len(sched), per_page):
        yield sched[start:start + per_page]

def get_event(e):
    """Takes event text, formats it per preferences that have been decided on, then returns it"""
    event = e.partition("-")[0].partition(":")[0].strip()
    for removal in [
            " cont'd",
            ' Docket',
            ' PTC',
            ' VOP & Notice to Appear',
            ' Judicial Review',
            ' Miscellaneous',
            ' Detention']:
        event = event.replace(removal, '')
    return event

def get_location(r):
    """Takes a dict of data, parsed from our csv, and returns a location based on some (fairly arbitrary) rules"""
    if r['room'].strip() == "Jury Assembly Room":
        location = "Jury Assembly"
    elif r['room']:
        location = "%s - %s Floor" % (r['room'], r['floor'])
    elif r['floor'] and r['event']:
        # If we don't have a room, they have to check with security
        location = r['floor'] + " Floor Security"

    elif r['event']:
        # There's a note
        location = ""

    return location


today, schedules = parse_judge_schedule()
if schedules['1st_appearances'] or schedules['traffic_misdemeanor']:
    print('<!-- ##### intro ##### -->')
    print(generate_intro(schedules))
for page_num, page in enumerate(paginate_schedule(schedules['judges'], 9)):
    print('<!-- ##### page %d ##### -->' % page_num)
    print(generate_table(page, True))
if schedules['other']:
    print('<!-- ##### other ##### -->')
    print(generate_table(schedules['other'], False))
