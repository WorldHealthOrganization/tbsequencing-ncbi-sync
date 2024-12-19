import re
from datetime import date, datetime
from typing import Optional

import dateutil.parser
import pycountry
from dateutil.relativedelta import relativedelta

from src.common import logs

log = logs.create_logger(__name__)

empty_date_matchers = [
    re.compile("missing"),
    re.compile("n/?a"),
    re.compile("not\s+collected"),
    re.compile("unknown"),
    re.compile("lab strain"),
    re.compile("not\s+determined"),
    re.compile("not\s+provided"),
    re.compile("not\s+present"),
    re.compile("not\s+applicable"),
    re.compile("not\s+known"),
    re.compile("-"),
    re.compile("none"),
    re.compile("0+"),
    re.compile("february 26, 207"),
    re.compile("not\s+available"),
]

replacement_regexp = {
    "Korea": "Korea, Republic of",
    "South Korea": "Korea, Republic of",
    "Iran": "Iran, Islamic Republic of",
    "Taiwan": "Taiwan, Province of China",
    "USA": "United States",
    "Democratic Republic of the Congo": "Congo, The Democratic Republic of the",
    "Swaziland": "Eswatini",
    "The former Yugoslav Republic of Macedonia": "North Macedonia",
    "Ivory Coast": "Côte d'Ivoire",
}

locations = {
    x: pycountry.countries.get(numeric="710")
    for x in {
        "Durban Chest Clinic",
        "Church of Scotland",
        "Catherine Booth",
        "King Dinuzulu Hospital",
        "Westville Prison",
        "M3 TB Hospital",
        "St Margaret's TB Hospital",
        "Dundee Hospital",
        "Siloah Clinic",
        "Goodwins Clinic",
        "Chwezi Clinic",
        "M3 TB Hospital",
        "M3 TB Hospital",
        "Christ The King Hospital",
        "St Mary's Kwa-Magwaza Hospital",
        "Church of Scotland",
        "Ethembeni Clinic",
        "Stanger Hospital",
        "Catherine Booth",
        "Siloah Clinic",
        "Richard's Bay Clinic",
        "St Margaret's Hospital",
        "St Margaret's Hospital",
        "Osindisweni Hospital - Occ Health, staff clinic",
    }
}

locations.update({"Point G Hospital": pycountry.countries.get(numeric="466")})
locations.update({"1reland": pycountry.countries.get(numeric="372")})


def get_collection_date(biosample_xml) -> tuple[Optional[date], Optional[date]]:
    assert biosample_xml.attrib["id"]
    elem = biosample_xml.find('Attributes/Attribute[@harmonized_name="collection_date"]')
    raw_date = (elem.text or "" if elem is not None else "").lower()

    raw_date = raw_date.strip(" \n\r")

    # In some cases we cannot parse the data, some comment indicate it, hence we skip it
    lower_bound_date, upper_bound_date = None, None
    if any(regex.match(raw_date) for regex in empty_date_matchers):
        return None, None

    if re.match(r"^[1-2][0-9]{3}$", raw_date):
        lower_bound_date = datetime.strptime(raw_date, "%Y").date()
        upper_bound_date = lower_bound_date + relativedelta(years=1)

    elif re.match(r"^[1-2][0-9]{3}-[0-9]{2}$", raw_date):
        lower_bound_date = datetime.strptime(raw_date, "%Y-%m").date()
        upper_bound_date = lower_bound_date + relativedelta(months=1)

    elif re.match(r"^[1-2][0-9]{3}/[1-2][0-9]{3}$", raw_date):
        a, b = raw_date.split("/")
        lower_bound_date = datetime.strptime(a, "%Y").date()
        upper_bound_date = datetime.strptime(b, "%Y").date()

    elif re.match(r"^[1-2][0-9]{3}-[0-9]{2}/[1-2][0-9]{3}-[0-9]{2}$", raw_date):
        a, b = raw_date.split("/")
        lower_bound_date = datetime.strptime(a, "%Y-%m").date()
        upper_bound_date = datetime.strptime(b, "%Y-%m").date() + relativedelta(months=1)

    elif re.match(r"^[1-2][0-9]{3}/[1-2][0-9]{3}/[1-2][0-9]{3}$", raw_date):
        a, b, c = raw_date.split("/")
        lower_bound_date = datetime.strptime(a, "%Y").date()
        upper_bound_date = datetime.strptime(c, "%Y").date() + relativedelta(years=1)

    elif re.match(r"^[1-2][0-9]{3}-[0-9]{1,2}-[0-9]{1,2}$", raw_date):
        try:
            lower_bound_date = datetime.strptime(raw_date, "%Y-%m-%d").date()
            upper_bound_date = datetime.strptime(raw_date, "%Y-%m-%d").date() + relativedelta(days=1)
        except ValueError:
            try:
                lower_bound_date = datetime.strptime("-".join(raw_date.split("-")[:-1]), "%Y-%m").date()
                upper_bound_date = lower_bound_date + relativedelta(months=1)
            except ValueError:
                pass

    elif re.match(r"^[1-2][0-9]{3}/[0-9]{1,2}/[0-9]{1,2}$", raw_date):
        lower_bound_date = datetime.strptime(raw_date, "%Y/%m/%d").date()
        upper_bound_date = datetime.strptime(raw_date, "%Y/%m/%d").date() + relativedelta(days=1)
    else:
        try:
            year = dateutil.parser.parse(raw_date).date().year
            lower_bound_date = datetime.strptime(str(year), "%Y")
            upper_bound_date = lower_bound_date + relativedelta(years=1)
        except ValueError:
            try:
                lower_bound_date = dateutil.parser.parse(raw_date.split("/")[0]).date()
                upper_bound_date = dateutil.parser.parse(raw_date.split("/")[1]).date() + relativedelta(months=1)
            except (ValueError, IndexError) as error:
                pass

    return lower_bound_date, upper_bound_date


def format_for_dbfield(lower_bound_date, upper_bound_date):
    if not lower_bound_date or not upper_bound_date:
        return None
    sampling_date = "[" + lower_bound_date.isoformat() + "," + upper_bound_date.isoformat() + ")"
    return sampling_date


def get_biosample_host_name(biosample_xml) -> str:
    host = biosample_xml.find('Attributes/Attribute[@harmonized_name="host"]')
    if host is not None and not any(regex.match(host.text.lower()) for regex in empty_date_matchers):
        host = host.text.strip('"')
    else:
        host = ""
    return host


def get_biosample_disease(biosample_xml):
    for disease_attribute in ["host_disease", "disease", "host_health_state", "health_state"]:
        elem = biosample_xml.find('Attributes/Attribute[@harmonized_name="' + disease_attribute + '"]')
        if elem is not None:
            raw = (elem.text or "" if elem is not None else "").lower()
            raw = raw.replace("disease:", "")
            raw = raw.strip(" \n\r")
            if any(regex.match(raw) for regex in empty_date_matchers):
                return None
            return raw
    return elem


def get_isolation_source(biosample_xml):
    source = biosample_xml.find('Attributes/Attribute[@harmonized_name="isolation_source"]')
    if source is not None and not any(regex.match(source.text.lower()) for regex in empty_date_matchers):
        source = source.text.strip()
    else:
        source = ""
    return source


def get_latitude_longitude(biosample_xml) -> tuple[Optional[str], Optional[str]]:
    elem = biosample_xml.find('Attributes/Attribute[@harmonized_name="lat_lon"]')
    raw = (elem.text or "" if elem is not None else "").lower()

    raw = raw.strip(" \n\r")

    # In some cases we cannot parse the data, some comment indicate it, hence we skip it
    if any(regex.match(raw) for regex in empty_date_matchers):
        return None, None

    raw = raw.upper()
    raw_loc = re.sub(r"([′″])([NWSE])", r"\1 \2", raw)
    latitude = "".join(raw_loc.split(" ")[:2]).strip()
    longitude = "".join(raw_loc.split(" ")[2:])
    coordinates = [latitude, longitude]
    for i, value in enumerate(coordinates):
        if re.match(r"^\d+°\d+′\d+″[NSWE]$", value):
            coordinates[i] = (
                str(
                    float(value.split("°")[0])
                    + float(value.split("°")[1].split("′")[0]) / 60
                    + float(value.split("°")[1].split("′")[1].split("″")[0]) / 3600
                )
                + value[-1]
            )
        elif re.match(r"^\d+°\d+′[NSWE]$", value):
            coordinates[i] = str(float(value.split("°")[0]) + float(value.split("°")[1].split("′")[0]) / 60) + value[-1]

    return longitude, latitude


def get_country(biosample_xml) -> tuple[Optional[str], Optional[str]]:
    elem = biosample_xml.find('Attributes/Attribute[@harmonized_name="geo_loc_name"]')

    raw_geo_data = elem.text if elem is not None else ""
    raw_geo_data = raw_geo_data.strip(" \n\r")

    if not raw_geo_data:
        return None, None

    if any(regex.match(raw_geo_data.lower()) for regex in empty_date_matchers):
        return None, None

    code = None
    extra = None

    country = pycountry.countries.get(
        name=replacement_regexp.get(raw_geo_data.split(":")[0].strip(), raw_geo_data.split(":")[0].strip())
    )
    if country is None:
        try:
            country = pycountry.countries.search_fuzzy(raw_geo_data.split(":")[0].strip())
            if len(country) == 1:
                code = str(country[0].alpha_3)
            else:
                print(raw_geo_data, country, biosample_xml.attrib["accession"])
                raise ValueError
        except LookupError:
            if raw_geo_data in locations.keys():
                code = locations[raw_geo_data].alpha_3
                extra = raw_geo_data
            else:
                pass
    else:
        code = str(country.alpha_3)
    if ":" in raw_geo_data:
        extra = raw_geo_data.split(":")[1].strip().replace("'", "").replace('"', "")
    return code, extra
