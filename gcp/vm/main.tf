resource "google_compute_instance" "default" {
    count = "${var.instance_count}"
    name = "${var.env}-${var.instance_name}-${count.index}"
    machine_type = "${var.instance_type}"
    zone = "${data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]}"
    
    boot_disk {
        initialize_params {
            image = "${data.google_compute_image.default.self_link}"
        }
    }

    network_interface {
        network = "${var.network}"
        subnetwork = "${element(random_shuffle.default.result, 0)}"

        access_config {
            // Ephemeral IP
        }
    }
}

resource "google_compute_disk" "data_disk" {
    count = "${var.create_data_volumes ? var.instance_count : 0}"
    name = "${var.env}-${var.instance_name}-${count.index}-data-disk"
    zone = "${data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]}"
    type = "${var.data_volume_type}"
    size = "${var.data_volume_size}"
    physical_block_size_bytes = 4096
}

resource "google_compute_attached_disk" "attachment" {
    count = "${var.create_data_volumes ? var.instance_count : 0}"
    device_name = "data-disk-${count.index}"
    disk = "${element(google_compute_disk.data_disk.*.self_link, count.index)}"
    instance = "${element(google_compute_instance.default.*.self_link, count.index)}"
}
