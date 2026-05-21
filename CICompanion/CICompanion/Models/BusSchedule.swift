//
//  BusSchedule.swift
//  CICompanion
//

import Foundation

struct BusRouteSchedule: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let sourceURL: String
    let pdfURL: String
    let directions: [BusScheduleDirection]
}

struct BusScheduleDirection: Identifiable, Hashable {
    let id: String
    let title: String
    let schedules: [BusServiceSchedule]
}

struct BusServiceSchedule: Identifiable, Hashable {
    let id: String
    let serviceDays: String
    let stops: [String]
    let trips: [BusTrip]
}

struct BusTrip: Hashable {
    let routeNumber: String
    let times: [String]
}

enum BusScheduleCatalog {
    static let routes: [BusRouteSchedule] = [
        hwy101,
        hwy126,
        eastCounty
    ]

    private static func trip(_ routeNumber: String, _ times: [String]) -> BusTrip {
        BusTrip(routeNumber: routeNumber, times: times)
    }

    private static func schedule(
        id: String,
        serviceDays: String,
        stops: [String],
        trips: [BusTrip]
    ) -> BusServiceSchedule {
        BusServiceSchedule(id: id, serviceDays: serviceDays, stops: stops, trips: trips)
    }

    private static let hwy101 = BusRouteSchedule(
        id: "hwy-101",
        title: "HWY 101",
        subtitle: "Routes 50-55",
        sourceURL: "https://www.goventura.org/vctc-transit/routes-schedules/hwy-101/",
        pdfURL: "https://www.goventura.org/wp-content/uploads/2026/02/2002_03_001_HWY101.pdf",
        directions: [
            BusScheduleDirection(
                id: "hwy-101-to-ventura",
                title: "To Ventura",
                schedules: [
                    schedule(
                        id: "hwy-101-to-ventura-weekday",
                        serviceDays: "Mon - Fri",
                        stops: [
                            "Thousand Oaks Transportation Ctr",
                            "Oaks Mall",
                            "Plaza at Mission Oaks",
                            "Camarillo Metrolink",
                            "Carmen Plaza - Camarillo City Hall",
                            "Camarillo Outlets - Food Court",
                            "Esplanade Mall",
                            "Government Center",
                            "Buena High School",
                            "Ventura College",
                            "Ventura Transit Center"
                        ],
                        trips: [
                            trip("50", ["6:25a", "6:35a", "6:48a", "6:54a", "7:00a", "7:06a", "7:18a", "7:29a", "FLAG", "7:37a", "7:42a"]),
                            trip("50", ["7:00a", "7:10a", "7:24a", "7:33a", "7:40a", "7:46a", "8:03a", "8:15a", "FLAG", "8:23a", "8:28a"]),
                            trip("55", ["8:20a", "8:30a", "8:43a", "8:53a", "9:00a", "9:06a", "9:18a", "9:29a", "FLAG", "9:37a", "9:41a"]),
                            trip("50", ["9:00a", "9:09a", "9:22a", "9:32a", "9:39a", "9:45a", "9:57a", "10:08a", "FLAG", "10:16a", "10:20a"]),
                            trip("50", ["10:00a", "10:09a", "10:22a", "10:29a", "10:36a", "10:42a", "10:54a", "11:05a", "FLAG", "11:13a", "11:17a"]),
                            trip("50", ["11:30a", "11:40a", "11:56a", "12:06p", "12:14p", "12:21p", "12:35p", "12:48p", "FLAG", "12:56p", "1:00p"]),
                            trip("50", ["12:30p", "12:40a", "12:56a", "1:06p", "1:14p", "1:21p", "1:35p", "1:48p", "FLAG", "1:56p", "2:00p"]),
                            trip("55", ["1:45p", "1:55p", "2:12p", "2:22p", "2:30p", "2:37p", "2:51p", "3:02p", "FLAG", "3:10p", "3:14p"]),
                            trip("50", ["2:35p", "2:45p", "3:02p", "3:12p", "3:20p", "3:27p", "3:42p", "3:55p", "FLAG", "4:03p", "4:07p"]),
                            trip("50", ["3:30p", "3:41p", "3:59p", "4:09p", "4:17p", "4:24p", "4:44p", "4:57p", "FLAG", "5:05p", "5:09p"]),
                            trip("50", ["4:15p", "4:26p", "4:42p", "4:52p", "5:00p", "5:07p", "5:27p", "5:38p", "FLAG", "5:46p", "5:50p"]),
                            trip("55X", ["6:05p", "-", "-", "6:24p", "-", "-", "6:44p", "-", "-", "-", "6:59p"]),
                            trip("50", ["6:30p", "6:41p", "6:56p", "7:06p", "7:13p", "7:20p", "7:32p", "7:43p", "FLAG", "7:51p", "7:55p"]),
                            trip("50", ["7:00p", "7:11p", "7:26p", "7:36p", "7:43p", "7:50p", "8:02p", "8:13p", "FLAG", "8:21p", "8:25p"])
                        ]
                    ),
                    schedule(
                        id: "hwy-101-to-ventura-sat",
                        serviceDays: "Sat",
                        stops: [
                            "Thousand Oaks Transportation Ctr",
                            "Oaks Mall",
                            "Plaza at Mission Oaks",
                            "Camarillo Metrolink",
                            "Carmen Plaza - Camarillo City Hall",
                            "Camarillo Outlets",
                            "Esplanade Mall",
                            "Ventura Pier",
                            "Ventura Transit Center"
                        ],
                        trips: [
                            trip("50", ["7:00am", "7:09am", "7:20am", "7:25am", "7:31am", "-", "7:42am", "7:55am", "8:06am"]),
                            trip("50", ["8:14am", "8:23am", "8:34am", "8:42am", "8:48am", "-", "8:59am", "9:10am", "9:19am"]),
                            trip("50", ["10:10am", "10:19am", "10:30am", "10:35am", "10:43am", "10:48am", "11:01am", "11:17am", "11:25am"]),
                            trip("50", ["11:42am", "11:51am", "12:04pm", "12:09pm", "12:15pm", "12:20pm", "12:33pm", "12:49pm", "12:57pm"]),
                            trip("50", ["12:55pm", "1:04pm", "1:18pm", "1:23pm", "1:29pm", "1:34pm", "1:45pm", "1:56pm", "2:04pm"]),
                            trip("50", ["2:20pm", "2:29pm", "2:42pm", "2:47pm", "2:55pm", "3:01pm", "3:14pm", "3:26pm", "3:35pm"]),
                            trip("50", ["4:00pm", "4:09pm", "4:31pm", "4:36pm", "4:42pm", "4:47pm", "4:59pm", "5:09pm", "5:21pm"]),
                            trip("50", ["5:45pm", "5:54pm", "6:16pm", "6:21pm", "6:27pm", "6:32pm", "6:43pm", "6:51pm", "7:03pm"])
                        ]
                    )
                ]
            ),
            BusScheduleDirection(
                id: "hwy-101-to-thousand-oaks",
                title: "To Thousand Oaks",
                schedules: [
                    schedule(
                        id: "hwy-101-to-thousand-oaks-weekday",
                        serviceDays: "Mon - Fri",
                        stops: [
                            "Ventura Transit Center",
                            "Ventura College",
                            "Buena High School",
                            "Government Center",
                            "Esplanade Mall",
                            "Camarillo Outlets",
                            "Carmen Plaza - Camarillo City Hall",
                            "Camarillo Metrolink",
                            "Plaza at Mission Oaks",
                            "Oaks Mall",
                            "Thousand Oaks Transportation Ctr",
                            "Westfield Topanga Plaza",
                            "Metro Orange Line De Soto Station",
                            "L.A. Pierce College",
                            "Kaiser Permanente Woodland Hills",
                            "Thousand Oaks Transportation Ctr"
                        ],
                        trips: [
                            trip("55X", ["6:15a", "-", "-", "-", "6:27a", "-", "-", "6:39a", "-", "-", "6:54a", "7:15a", "7:19a", "7:21a", "7:24a", "8:05a"]),
                            trip("50", ["6:30a", "6:35a", "FLAG", "6:42a", "6:52a", "7:03a", "7:07a", "7:15a", "7:23a", "7:41a", "7:52a", "-", "-", "-", "-", "-"]),
                            trip("50", ["7:45a", "7:50a", "FLAG", "7:59a", "8:09a", "8:23a", "8:29a", "8:36a", "8:44a", "9:03a", "9:13a", "-", "-", "-", "-", "-"]),
                            trip("50", ["8:45a", "8:50a", "FLAG", "8:59a", "9:09a", "9:23a", "9:29a", "9:36a", "9:44a", "10:02a", "10:12a", "-", "-", "-", "-", "-"]),
                            trip("50", ["9:55a", "10:00a", "FLAG", "10:09a", "10:19a", "10:31a", "10:37a", "10:44a", "10:52a", "11:09a", "11:19a", "-", "-", "-", "-", "-"]),
                            trip("55X", ["11:30a", "-", "-", "11:40a", "11:50a", "-", "-", "12:01p", "12:08p", "-", "12:23p", "12:50p", "12:54p", "12:56p", "1:04p", "1:30p"]),
                            trip("50", ["11:45a", "11:49a", "FLAG", "11:58a", "12:08p", "12:20p", "12:26p", "12:33p", "12:41p", "12:58p", "1:08p", "-", "-", "-", "-", "-"]),
                            trip("50", ["1:00p", "1:05p", "FLAG", "1:14p", "1:24p", "1:37p", "1:44p", "1:51p", "1:59p", "2:19p", "2:31p", "-", "-", "-", "-", "-"]),
                            trip("50", ["2:30p", "2:35p", "FLAG", "2:44p", "2:55p", "3:10p", "3:17p", "3:24p", "3:32p", "3:52p", "4:05p", "-", "-", "-", "-", "-"]),
                            trip("55X", ["3:30p", "-", "-", "3:40p", "3:50p", "-", "-", "4:10p", "4:17p", "-", "4:34p", "5:10p", "5:14p", "5:16p", "5:24p", "5:50p"]),
                            trip("50", ["4:10p", "4:15p", "FLAG", "4:24p", "4:34p", "4:49p", "4:57p", "5:04p", "5:12p", "5:32p", "5:44p", "-", "-", "-", "-", "-"]),
                            trip("50", ["5:15p", "5:20p", "FLAG", "5:29p", "5:40p", "5:55p", "6:03p", "6:10p", "6:18p", "6:37p", "6:49p", "-", "-", "-", "-", "-"]),
                            trip("50", ["6:40p", "6:45p", "FLAG", "6:54p", "7:04p", "7:18p", "7:24p", "7:31p", "7:39p", "7:58p", "8:08p", "-", "-", "-", "-", "-"]),
                            trip("50", ["7:50p", "7:55p", "FLAG", "8:02p", "8:12p", "8:24p", "8:30p", "8:36p", "-", "-", "-", "-", "-", "-", "-", "-"])
                        ]
                    ),
                    schedule(
                        id: "hwy-101-to-thousand-oaks-sat",
                        serviceDays: "Sat",
                        stops: [
                            "Ventura Pier",
                            "Ventura Transit Center",
                            "Esplanade Mall",
                            "Camarillo Outlets",
                            "Carmen Plaza - Camarillo City Hall",
                            "Camarillo Metrolink",
                            "Plaza at Mission Oaks",
                            "Oaks Mall",
                            "Thousand Oaks Transportation Center"
                        ],
                        trips: [
                            trip("50", ["-", "7:00am", "7:12am", "-", "7:24am", "7:30am", "7:48am", "-", "7:59am"]),
                            trip("50", ["7:55am", "8:20am", "8:32am", "-", "8:44am", "8:50am", "8:56am", "9:11am", "9:21am"]),
                            trip("50", ["9:10am", "9:24am", "9:36am", "9:46am", "9:52am", "9:58am", "10:04am", "10:19am", "10:29am"]),
                            trip("50", ["11:18am", "11:40am", "11:52am", "12:02pm", "12:08pm", "12:14pm", "12:20pm", "12:35pm", "12:45pm"]),
                            trip("50", ["12:49pm", "1:10pm", "1:22pm", "1:32pm", "1:38pm", "1:44pm", "-", "2:03pm", "2:13pm"]),
                            trip("50", ["1:56pm", "2:10pm", "2:22pm", "2:32pm", "2:38pm", "2:44pm", "2:50pm", "3:05pm", "3:15pm"]),
                            trip("50", ["3:26pm", "3:45pm", "3:57pm", "4:07pm", "4:13pm", "4:19pm", "-", "4:38pm", "4:48pm"]),
                            trip("50", ["5:09pm", "5:25pm", "5:37pm", "5:49pm", "5:54pm", "5:59pm", "6:04pm", "DROP", "DROP"])
                        ]
                    )
                ]
            )
        ]
    )

    private static let hwy126 = BusRouteSchedule(
        id: "hwy-126",
        title: "HWY 126",
        subtitle: "Route 60",
        sourceURL: "https://www.goventura.org/vctc-transit/routes-schedules/hwy-126/",
        pdfURL: "https://www.goventura.org/wp-content/uploads/2026/02/2002_03_004_Hwy-126.pdf",
        directions: [
            BusScheduleDirection(
                id: "hwy-126-to-fillmore",
                title: "To Fillmore",
                schedules: [
                    schedule(
                        id: "hwy-126-to-fillmore-weekday",
                        serviceDays: "Mon - Fri",
                        stops: [
                            "Ventura Transit Center",
                            "St. Bonaventure High School",
                            "Ventura County Medical Center",
                            "Ventura College",
                            "Buena High School",
                            "Government Center",
                            "Wells Center",
                            "Santa Paula Kmart",
                            "Santa Paula DMV",
                            "Santa Paula City Hall",
                            "Fillmore Senior Center"
                        ],
                        trips: [
                            trip("60", ["6:30am", "FLAG", "FLAG", "6:37am", "FLAG", "6:43am", "6:56am", "7:09am", "7:15am", "7:18am", "7:34am"]),
                            trip("60", ["7:30am", "FLAG", "FLAG", "7:37am", "FLAG", "7:43am", "7:56am", "8:09am", "8:15am", "8:18am", "8:34am"]),
                            trip("60", ["8:30am", "FLAG", "FLAG", "8:37am", "FLAG", "8:43am", "8:56am", "9:09am", "9:15am", "9:18am", "9:34am"]),
                            trip("60", ["9:30am", "FLAG", "FLAG", "9:37am", "FLAG", "9:43am", "9:56am", "10:09am", "10:15am", "10:18am", "10:34am"]),
                            trip("60", ["10:30am", "FLAG", "FLAG", "10:37am", "FLAG", "10:43am", "10:56am", "11:09am", "11:15am", "11:18am", "11:34am"]),
                            trip("60", ["11:30am", "FLAG", "FLAG", "11:37am", "FLAG", "11:43am", "11:56am", "12:09pm", "12:15pm", "12:18pm", "12:34pm"]),
                            trip("60", ["12:30pm", "FLAG", "FLAG", "12:37pm", "FLAG", "12:43pm", "12:56pm", "1:09pm", "1:15pm", "1:18pm", "1:34pm"]),
                            trip("60", ["1:30pm", "FLAG", "FLAG", "1:37pm", "FLAG", "1:43pm", "1:56pm", "2:09pm", "2:15pm", "2:18pm", "2:34pm"]),
                            trip("60", ["2:30pm", "FLAG", "FLAG", "2:37pm", "FLAG", "2:43pm", "2:56pm", "3:09pm", "3:15pm", "3:18pm", "3:34pm"]),
                            trip("60", ["3:30pm", "FLAG", "FLAG", "3:37pm", "FLAG", "3:43pm", "3:56pm", "4:09pm", "4:15pm", "4:18pm", "4:34pm"]),
                            trip("60", ["4:30pm", "FLAG", "FLAG", "4:37pm", "FLAG", "4:43pm", "4:56pm", "5:09pm", "5:15pm", "5:18pm", "5:34pm"]),
                            trip("60", ["5:30pm", "FLAG", "FLAG", "5:37pm", "FLAG", "5:43pm", "5:56pm", "6:09pm", "6:15pm", "6:18pm", "6:34pm"]),
                            trip("60", ["6:30pm", "FLAG", "FLAG", "6:37pm", "FLAG", "6:43pm", "6:56pm", "7:09pm", "7:15pm", "7:18pm", "7:34pm"]),
                            trip("60", ["7:30pm", "FLAG", "FLAG", "7:37pm", "FLAG", "7:43pm", "7:56pm", "8:09pm", "8:15pm", "8:18pm", "8:34pm"]),
                            trip("60", ["8:30pm", "FLAG", "FLAG", "8:34pm", "FLAG", "8:40pm", "8:50pm", "9:00pm", "9:06pm", "9:09pm", "9:24pm"]),
                            trip("60", ["9:30pm", "FLAG", "FLAG", "9:34pm", "FLAG", "9:40pm", "9:50pm", "10:00pm", "10:06pm", "10:09pm", "10:24pm"])
                        ]
                    ),
                    schedule(
                        id: "hwy-126-to-fillmore-weekend",
                        serviceDays: "Sat - Sun",
                        stops: [
                            "Ventura Pier",
                            "Ventura Transit Center",
                            "Ventura College",
                            "Wells Center",
                            "Santa Paula Kmart",
                            "Santa Paula DMV",
                            "Santa Paula City Hall",
                            "Fillmore Senior Center"
                        ],
                        trips: [
                            trip("60", ["8:05am", "8:15am", "8:20am", "8:30am", "8:40am", "8:44am", "8:47am", "8:57am"]),
                            trip("60", ["9:05am", "9:15am", "9:20am", "9:30am", "9:40am", "9:44am", "9:47am", "9:57am"]),
                            trip("60", ["10:00am", "10:10am", "10:15am", "10:25am", "10:35am", "10:39am", "10:42am", "10:52am"]),
                            trip("60", ["11:15am", "11:25am", "11:30am", "11:40am", "11:50am", "11:54am", "11:57am", "12:07pm"]),
                            trip("60", ["12:10pm", "12:20pm", "12:25pm", "12:35pm", "12:45pm", "12:49pm", "12:52pm", "1:02pm"]),
                            trip("60", ["1:20pm", "1:30pm", "1:35pm", "1:45pm", "1:55pm", "1:59pm", "2:02pm", "2:12pm"]),
                            trip("60", ["2:20pm", "2:30pm", "2:35pm", "2:45pm", "2:55pm", "2:59pm", "3:02pm", "3:12pm"]),
                            trip("60", ["3:25pm", "3:35pm", "3:40pm", "3:50pm", "4:00pm", "4:04pm", "4:07pm", "4:17pm"]),
                            trip("60", ["5:30pm", "5:40pm", "5:45pm", "5:55pm", "6:05pm", "6:09pm", "6:12pm", "6:22pm"]),
                            trip("60", ["6:35pm", "6:45pm", "6:50pm", "7:00pm", "7:10pm", "7:14pm", "7:17pm", "7:27pm"])
                        ]
                    )
                ]
            ),
            BusScheduleDirection(
                id: "hwy-126-to-ventura",
                title: "To Ventura",
                schedules: [
                    schedule(
                        id: "hwy-126-to-ventura-weekday",
                        serviceDays: "Mon - Fri",
                        stops: [
                            "Fillmore Senior Center",
                            "Santa Paula City Hall",
                            "Santa Paula DMV",
                            "Santa Paula Kmart",
                            "Wells Center",
                            "Government Center",
                            "Buena High School",
                            "Ventura College",
                            "Ventura County Medical Center",
                            "St. Bonaventure High School",
                            "Ventura Transit Center"
                        ],
                        trips: [
                            trip("60", ["5:15am", "5:34am", "5:39am", "5:43am", "5:50am", "6:00am", "FLAG", "6:09am", "FLAG", "FLAG", "6:14am"]),
                            trip("60", ["6:15am", "6:34am", "6:39am", "6:43am", "6:50am", "7:00am", "FLAG", "7:09am", "FLAG", "FLAG", "7:14am"]),
                            trip("60", ["7:15am", "7:34am", "7:39am", "7:43am", "7:50am", "8:00am", "FLAG", "8:09am", "FLAG", "FLAG", "8:14am"]),
                            trip("60", ["8:15am", "8:34am", "8:39am", "8:43am", "8:50am", "9:00am", "FLAG", "9:09am", "FLAG", "FLAG", "9:14am"]),
                            trip("60", ["9:15am", "9:34am", "9:39am", "9:43am", "9:50am", "10:00am", "FLAG", "10:09am", "FLAG", "FLAG", "10:14am"]),
                            trip("60", ["10:15am", "10:34am", "10:39am", "10:43am", "10:50am", "11:00am", "FLAG", "11:09am", "FLAG", "FLAG", "11:14am"]),
                            trip("60", ["11:15am", "11:34am", "11:39am", "11:43am", "11:50am", "12:00pm", "FLAG", "12:09pm", "FLAG", "FLAG", "12:14pm"]),
                            trip("60", ["12:15pm", "12:34pm", "12:39pm", "12:43pm", "12:50pm", "1:00pm", "FLAG", "1:09pm", "FLAG", "FLAG", "1:14pm"]),
                            trip("60", ["1:15pm", "1:34pm", "1:39pm", "1:43pm", "1:50pm", "2:00pm", "FLAG", "2:09pm", "FLAG", "FLAG", "2:14pm"]),
                            trip("60", ["2:15pm", "2:34pm", "2:39pm", "2:43pm", "2:50pm", "3:00pm", "FLAG", "3:09pm", "FLAG", "FLAG", "3:14pm"]),
                            trip("60", ["3:15pm", "3:34pm", "3:39pm", "3:43pm", "3:50pm", "4:00pm", "FLAG", "4:09pm", "FLAG", "FLAG", "4:14pm"]),
                            trip("60", ["4:15pm", "4:34pm", "4:39pm", "4:43pm", "4:50pm", "5:00pm", "FLAG", "5:09pm", "FLAG", "FLAG", "5:14pm"]),
                            trip("60", ["5:15pm", "5:34pm", "5:39pm", "5:43pm", "5:50pm", "6:00pm", "FLAG", "6:09pm", "FLAG", "FLAG", "6:14pm"]),
                            trip("60", ["6:15pm", "6:34pm", "6:39pm", "6:43pm", "6:50pm", "7:00pm", "FLAG", "7:08pm", "FLAG", "FLAG", "7:14pm"]),
                            trip("60", ["7:15pm", "7:34pm", "7:39pm", "7:43pm", "7:50pm", "8:00pm", "FLAG", "8:08pm", "FLAG", "FLAG", "8:13pm"]),
                            trip("60", ["8:15pm", "8:34pm", "8:39pm", "8:43pm", "8:50pm", "9:00pm", "FLAG", "9:09pm", "FLAG", "FLAG", "9:13pm"])
                        ]
                    ),
                    schedule(
                        id: "hwy-126-to-ventura-weekend",
                        serviceDays: "Sat - Sun",
                        stops: [
                            "Fillmore Senior Center",
                            "Santa Paula City Hall",
                            "Santa Paula DMV",
                            "Santa Paula Kmart",
                            "Wells Center",
                            "Ventura College",
                            "Ventura Transit Center",
                            "Ventura Pier"
                        ],
                        trips: [
                            trip("60", ["8:00am", "8:20am", "8:23am", "8:26am", "8:36am", "8:45am", "8:50am", "8:59am"]),
                            trip("60", ["9:00am", "9:20am", "9:23am", "9:26am", "9:36am", "9:45am", "9:50am", "9:59am"]),
                            trip("60", ["10:15am", "10:35am", "10:38am", "10:41am", "10:51am", "11:00am", "11:05am", "11:14am"]),
                            trip("60", ["11:10am", "11:30am", "11:33am", "11:36am", "11:46am", "11:55am", "12:00pm", "12:09pm"]),
                            trip("60", ["12:20pm", "12:40pm", "12:43pm", "12:46pm", "12:56pm", "1:05pm", "1:10pm", "1:19pm"]),
                            trip("60", ["1:20pm", "1:40pm", "1:43pm", "1:46pm", "1:56pm", "2:05pm", "2:10pm", "2:19pm"]),
                            trip("60", ["2:25pm", "2:45pm", "2:48pm", "2:51pm", "3:01pm", "3:10pm", "3:15pm", "3:24pm"]),
                            trip("60", ["3:30pm", "3:50pm", "3:53pm", "3:56pm", "4:06pm", "4:15pm", "4:20pm", "4:29pm"]),
                            trip("60", ["4:30pm", "4:50pm", "4:53pm", "4:56pm", "5:06pm", "5:15pm", "5:20pm", "5:29pm"]),
                            trip("60", ["5:35pm", "5:55pm", "5:58pm", "6:01pm", "6:11pm", "6:20pm", "6:25pm", "6:34pm"])
                        ]
                    )
                ]
            )
        ]
    )

    private static let eastCounty = BusRouteSchedule(
        id: "east-county",
        title: "East County",
        subtitle: "Routes 70-74X",
        sourceURL: "https://www.goventura.org/vctc-transit/routes-schedules/east-county/",
        pdfURL: "https://www.goventura.org/wp-content/uploads/2026/02/2002_03_005_East-County_Color-Corrected.pdf",
        directions: [
            BusScheduleDirection(
                id: "east-county-to-thousand-oaks",
                title: "To Thousand Oaks",
                schedules: [
                    schedule(
                        id: "east-county-to-thousand-oaks-weekday",
                        serviceDays: "Mon - Fri",
                        stops: [
                            "Cochran St/Galena Av",
                            "Simi Town Center",
                            "Moorpark College",
                            "Princeton Av/Amherst St",
                            "Moorpark Metrolink Station",
                            "Thousand Oaks Library/Teen Center",
                            "Thousand Oaks Transportation Center",
                            "Oaks Mall",
                            "Newbury Park Smart & Final"
                        ],
                        trips: [
                            trip("74", ["6:38am", "6:48am", "6:58am", "FLAG", "7:10am", "-", "7:30am", "7:40am", "-"]),
                            trip("71", ["8:15am", "8:25am", "8:37am", "FLAG", "8:49am", "9:04am", "9:14am", "9:24am", "-"]),
                            trip("70", ["-", "9:55am", "10:07am", "FLAG", "10:19am", "10:34am", "10:44am", "10:54am", "11:02am"]),
                            trip("71", ["11:15am", "11:25am", "11:37am", "FLAG", "11:49am", "12:04pm", "12:14pm", "12:24pm", "-"]),
                            trip("70", ["-", "12:40pm", "12:52pm", "FLAG", "1:04pm", "1:19pm", "1:29pm", "1:39pm", "1:47pm"]),
                            trip("71", ["1:45pm", "1:55pm", "2:07pm", "FLAG", "2:19pm", "2:34pm", "2:44pm", "2:54pm", "-"]),
                            trip("70", ["-", "3:00pm", "3:12pm", "FLAG", "3:24pm", "3:39pm", "3:49pm", "3:59pm", "4:07pm"]),
                            trip("71", ["5:15pm", "5:25pm", "5:37pm", "FLAG", "5:49pm", "6:04pm", "6:14pm", "6:24pm", "-"]),
                            trip("74", ["7:10pm", "7:20pm", "7:32pm", "FLAG", "7:44pm", "-", "8:02pm", "8:12pm", "-"])
                        ]
                    ),
                    schedule(
                        id: "east-county-to-thousand-oaks-saturday",
                        serviceDays: "Saturday",
                        stops: [
                            "Simi Town Center",
                            "Moorpark College",
                            "Princeton Av/Amherst St",
                            "Moorpark Metrolink Station",
                            "Thousand Oaks Library/Teen Center",
                            "Thousand Oaks Transportation Center",
                            "Oaks Mall",
                            "Newbury Park Smart & Final"
                        ],
                        trips: [
                            trip("70", ["9:05am", "-", "-", "9:22am", "9:37am", "9:47am", "9:57am", "-"]),
                            trip("71", ["11:00am", "-", "-", "11:17am", "11:32am", "11:41am", "11:50am", "11:57am"]),
                            trip("70c", ["2:15pm", "2:25pm", "FLAG", "2:36pm", "2:49pm", "2:59pm", "3:09pm", "-"]),
                            trip("71", ["4:15pm", "-", "-", "4:32pm", "4:47pm", "4:56pm", "5:05pm", "5:12pm"])
                        ]
                    )
                ]
            ),
            BusScheduleDirection(
                id: "east-county-to-simi-valley",
                title: "To Simi Valley",
                schedules: [
                    schedule(
                        id: "east-county-to-simi-valley-weekday",
                        serviceDays: "Mon - Fri",
                        stops: [
                            "Newbury Park Smart & Final",
                            "Oaks Mall",
                            "Thousand Oaks Transportation Center",
                            "Thousand Oaks Library/Teen Center",
                            "Moorpark Metrolink Station",
                            "Princeton Av/Amherst St",
                            "Moorpark College",
                            "Simi Town Center",
                            "Cochran St/Galena Av"
                        ],
                        trips: [
                            trip("74x", ["-", "5:40am", "5:50am", "-", "6:08am", "-", "-", "6:23am", "6:31am"]),
                            trip("71", ["-", "6:50am", "7:00am", "7:10am", "7:25am", "FLAG", "7:37am", "7:49am", "7:57am"]),
                            trip("70", ["7:55am", "8:03am", "8:13am", "8:23am", "8:38am", "FLAG", "8:50am", "9:02am", "-"]),
                            trip("71", ["-", "9:30am", "9:40am", "9:50am", "10:05am", "FLAG", "10:17am", "10:29am", "10:37am"]),
                            trip("70", ["11:05am", "11:13am", "11:23am", "11:33am", "11:48am", "FLAG", "12:00pm", "12:12pm", "-"]),
                            trip("71", ["-", "12:30pm", "12:40pm", "12:50pm", "1:05pm", "FLAG", "1:17pm", "1:29pm", "1:37pm"]),
                            trip("70", ["1:20pm", "1:28pm", "1:38pm", "1:48pm", "2:03pm", "FLAG", "2:15pm", "2:27pm", "-"]),
                            trip("71", ["-", "3:50pm", "4:00pm", "4:10pm", "4:25pm", "FLAG", "4:37pm", "4:49pm", "4:57pm"]),
                            trip("70", ["5:20pm", "5:28pm", "5:38pm", "5:48pm", "6:03pm", "FLAG", "6:15pm", "6:27pm", "6:37pm"]),
                            trip("71", ["-", "6:30pm", "6:40pm", "6:50pm", "7:05pm", "FLAG", "7:17pm", "7:29pm", "7:37pm"])
                        ]
                    ),
                    schedule(
                        id: "east-county-to-simi-valley-saturday",
                        serviceDays: "Saturday",
                        stops: [
                            "Newbury Park Smart & Final",
                            "Oaks Mall",
                            "Thousand Oaks Transportation Center",
                            "Thousand Oaks Library/Teen Center",
                            "Moorpark Metrolink Station",
                            "Princeton Av/Amherst St",
                            "Moorpark College",
                            "Simi Town Center"
                        ],
                        trips: [
                            trip("71", ["7:40am", "7:47am", "7:57am", "8:07am", "8:19am", "-", "-", "8:34am"]),
                            trip("70c", ["-", "9:45am", "9:55am", "10:05am", "10:18am", "FLAG", "10:27am", "10:39am"]),
                            trip("71", ["12:50pm", "12:57pm", "1:07pm", "1:17pm", "1:30pm", "-", "-", "1:45pm"]),
                            trip("70", ["-", "3:00pm", "3:10pm", "3:20pm", "3:33pm", "-", "-", "3:48pm"])
                        ]
                    )
                ]
            )
        ]
    )
}
