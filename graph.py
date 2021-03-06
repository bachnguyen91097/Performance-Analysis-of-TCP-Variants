
import os
import matplotlib.pyplot as plt

variants = ["Tahoe", "Reno", "NewReno", "Vegas"]
cbr_list = [1, 2, 3, 4, 5, 6, 8, 9, 10]


def get_results(variant):
    throughput_list = []
    latency_list = []
    drop_rate_list = []

    for cbr_rate in cbr_list:
        os.system("ns exp1.tcl " + variant + " " + str(cbr_rate))
        trace_analysis = open(variant + '_' + str(cbr_rate) + '_output.tr').readlines()
        line_count = 0
        bits = 0
        tlat = 0.0
        no = 0
        t_send = {}
        t_arr = {}
        total = 0
        drop = 0

        for line in trace_analysis:
            tru = line.split()
            event = tru[0]
            time = float(tru[1])
            source = tru[2]
            destn = tru[3]
            size = int(tru[5])
            fid = tru[7]
            seq = (tru[10])

            if fid == '1':
                if event == '+':
                    if source == '0':
                        if line_count == 0:
                            start = time
                            line_count += 1
                        t_send.update({seq: time})
                    drop += 1

                if event == 'r':
                    bits += 8 * size
                    end = time
                    if destn == '0':
                        t_arr.update({seq: time})
                    total += 1

        duration = end - start
        throughput = bits / duration / (1024 * 1024)
        throughput_list.append(throughput)

        pack = {x for x in t_send.keys() if x in t_arr.keys()}
        for i in pack:
            start = t_send[i]
            end = t_arr[i]
            duration = end - start
            if duration > 0:
                tlat += duration
                no += 1
        latency = (tlat / no) * 1000
        latency_list.append(latency)

        drop_rate = (float(drop) / float(total)) * 100
        drop_rate_list.append(drop_rate)

    return throughput_list, latency_list, drop_rate_list


def plot_throughput_graph(cbr_list, throughput_mapper):
    for variant in throughput_mapper:
        plt.plot(throughput_mapper[variant], cbr_list, label=variant, marker='o', markersize=12)

    plt.legend()
    plt.xlabel('Throughput')
    plt.ylabel('CBR')
    plt.title('Throughput vs. CBR')
    plt.show()


def plot_latency_graph(cbr_list, latency_mapper):
    for variant in latency_mapper:
        plt.plot(latency_mapper[variant], cbr_list, label=variant, marker='o', markersize=12)

    plt.legend()
    plt.xlabel('Latency')
    plt.ylabel('CBR')
    plt.title('Latency vs. CBR')
    plt.show()


def plot_drop_rate_graph(cbr_list, drop_rate_mapper):
    for variant in drop_rate_mapper:
        plt.plot(drop_rate_mapper[variant], cbr_list, label=variant, marker='o', markersize=12)

    plt.legend()
    plt.xlabel('Drop Rate')
    plt.ylabel('CBR')
    plt.title('Drop Rate vs. CBR')
    plt.show()


def draw_graph():
    throughput_mapper = {}
    latency_mapper = {}
    drop_rate_mapper = {}
    for variant in variants:
        throughput_list, latency_list, drop_rate_list = get_results(variant)

        throughput_mapper[variant] = throughput_list
        latency_mapper[variant] = latency_list
        drop_rate_mapper[variant] = drop_rate_list
    print(throughput_mapper)
    print(latency_mapper)
    print(drop_rate_mapper)

    plot_throughput_graph(cbr_list, throughput_mapper)
    plot_latency_graph(cbr_list, latency_mapper)
    plot_drop_rate_graph(cbr_list, drop_rate_mapper)

if __name__ == "__main__":
    draw_graph()
    os.system("rm *.tr")
